const rideDb = require('../config/rideDb');

/**
 * UCB (Upper Confidence Bound) score বের করা।
 * total_shown == 0 হলে ucb_score = Infinity (cold-start exploration —
 * সম্পূর্ণ নতুন offer সবসময় সবার আগে দেখানো হবে)
 */
const calculateUcbScore = (totalShown, totalAccepted, totalRoundsForArmType) => {
  if (!totalShown || totalShown === 0) {
    return Infinity;
  }
  const avgReward = totalAccepted / totalShown;
  const confidence = Math.sqrt(
    (2 * Math.log(Math.max(totalRoundsForArmType, 1))) / totalShown
  );
  return avgReward + confidence;
};

/**
 * নির্দিষ্ট arm_type এর জন্য সব bandit_arms_state row আনে
 * (শুধু global state — context_user_id/context_time_slot ছাড়া),
 * arm_identifier -> row ম্যাপ করে রিটার্ন করে, সাথে total_rounds (সব arm মিলিয়ে মোট shown)
 */
const getArmsStateMap = async (armType) => {
  const result = await rideDb.query(
    `SELECT arm_identifier, total_shown, total_accepted, avg_reward
     FROM bandit_arms_state
     WHERE arm_type = $1
       AND context_user_id IS NULL
       AND context_time_slot IS NULL`,
    [armType]
  );

  const map = new Map();
  let totalRounds = 0;
  for (const row of result.rows) {
    map.set(row.arm_identifier, row);
    totalRounds += row.total_shown;
  }
  return { map, totalRounds };
};

/**
 * offers array কে UCB score অনুযায়ী descending sort করে রিটার্ন করে।
 * প্রতিটা offer object অপরিবর্তিত থাকে (শুধু order বদলায়)।
 */
const sortOffersByUcb = async (offers, armType) => {
  if (!Array.isArray(offers) || offers.length === 0) return offers;

  const { map, totalRounds } = await getArmsStateMap(armType);

  const scored = offers.map((offer) => {
    const state = map.get(offer.offer_id);
    const totalShown = state ? state.total_shown : 0;
    const totalAccepted = state ? state.total_accepted : 0;
    return {
      offer,
      ucbScore: calculateUcbScore(totalShown, totalAccepted, totalRounds),
    };
  });

  scored.sort((a, b) => {
    if (a.ucbScore === Infinity && b.ucbScore === Infinity) return 0;
    if (a.ucbScore === Infinity) return -1;
    if (b.ucbScore === Infinity) return 1;
    return b.ucbScore - a.ucbScore;
  });

  return scored.map((s) => s.offer);
};

/**
 * bandit_arms_state এ "shown" event এর জন্য UPSERT (manual — ON CONFLICT ব্যবহার
 * করা হয়নি, কারণ context_user_id/context_time_slot NULL থাকায় unique constraint
 * কাজ করবে না)
 */
const upsertBanditShown = async (armType, armIdentifier) => {
  const existing = await rideDb.query(
    `SELECT arm_id, total_shown, total_accepted
     FROM bandit_arms_state
     WHERE arm_type = $1
       AND arm_identifier = $2
       AND context_user_id IS NULL
       AND context_time_slot IS NULL`,
    [armType, armIdentifier]
  );

  if (existing.rowCount > 0) {
    const row = existing.rows[0];
    const newShown = row.total_shown + 1;
    const newAvgReward = newShown > 0 ? row.total_accepted / newShown : 0;
    await rideDb.query(
      `UPDATE bandit_arms_state
       SET total_shown = $1, avg_reward = $2, last_updated_at = CURRENT_TIMESTAMP
       WHERE arm_id = $3`,
      [newShown, newAvgReward, row.arm_id]
    );
  } else {
    await rideDb.query(
      `INSERT INTO bandit_arms_state (arm_type, arm_identifier, total_shown, avg_reward)
       VALUES ($1, $2, 1, 0.0)`,
      [armType, armIdentifier]
    );
  }
};

/**
 * bandit_arms_state এ "accepted" event এর জন্য UPSERT
 */
const upsertBanditAccepted = async (armType, armIdentifier) => {
  const existing = await rideDb.query(
    `SELECT arm_id, total_shown, total_accepted
     FROM bandit_arms_state
     WHERE arm_type = $1
       AND arm_identifier = $2
       AND context_user_id IS NULL
       AND context_time_slot IS NULL`,
    [armType, armIdentifier]
  );

  if (existing.rowCount > 0) {
    const row = existing.rows[0];
    const newAccepted = row.total_accepted + 1;
    const newAvgReward = row.total_shown > 0 ? newAccepted / row.total_shown : 1.0;
    await rideDb.query(
      `UPDATE bandit_arms_state
       SET total_accepted = $1, avg_reward = $2, last_updated_at = CURRENT_TIMESTAMP
       WHERE arm_id = $3`,
      [newAccepted, newAvgReward, row.arm_id]
    );
  } else {
    // shown event ছাড়াই সরাসরি accepted (তত্ত্বগতভাবে ঘটবে না, তবুও safe fallback)
    await rideDb.query(
      `INSERT INTO bandit_arms_state (arm_type, arm_identifier, total_shown, total_accepted, avg_reward)
       VALUES ($1, $2, 0, 1, 1.0)`,
      [armType, armIdentifier]
    );
  }
};

/**
 * promo_interactions এ "shown" row UPSERT করে (একই user+offer এর জন্য shown_at
 * আপডেট হয়, নতুন row বারবার তৈরি হয় না), সাথে bandit_arms_state ও আপডেট করে।
 * userId না থাকলে (guest/unauthenticated) কিছুই করবে না।
 */
const logOffersShown = async (userId, offers, armType) => {
  if (!userId || !Array.isArray(offers) || offers.length === 0) return;

  for (const offer of offers) {
    if (!offer.offer_id) continue;

    try {
      const existing = await rideDb.query(
        `SELECT interaction_id FROM promo_interactions
         WHERE user_id = $1 AND offer_id = $2 AND action = 'shown'
         LIMIT 1`,
        [userId, offer.offer_id]
      );

      if (existing.rowCount > 0) {
        await rideDb.query(
          `UPDATE promo_interactions
           SET shown_at = CURRENT_TIMESTAMP
           WHERE interaction_id = $1`,
          [existing.rows[0].interaction_id]
        );
      } else {
        await rideDb.query(
          `INSERT INTO promo_interactions (user_id, offer_id, action)
           VALUES ($1, $2, 'shown')`,
          [userId, offer.offer_id]
        );
      }

      await upsertBanditShown(armType, offer.offer_id);
    } catch (err) {
      console.error('logOffersShown error:', err.message);
    }
  }
};

/**
 * applyOffer() সফল হলে "accepted" event log করে — reward = +1.0
 */
const logOfferAccepted = async (userId, offerId, armType) => {
  if (!userId || !offerId) return;

  try {
    await rideDb.query(
      `INSERT INTO promo_interactions (user_id, offer_id, action, action_timestamp, reward_value)
       VALUES ($1, $2, 'accepted', CURRENT_TIMESTAMP, 1.0)`,
      [userId, offerId]
    );

    await upsertBanditAccepted(armType, offerId);
  } catch (err) {
    console.error('logOfferAccepted error:', err.message);
  }
};

module.exports = {
  calculateUcbScore,
  sortOffersByUcb,
  logOffersShown,
  logOfferAccepted,
};
