// কে এখন কোন CoRide চ্যাট সেশনে (স্ক্রিনে) সক্রিয়ভাবে আছে সেটা ট্র্যাক করে
const viewers = new Map(); // sessionId -> Map(userId -> Set(socketId))
const socketSessionMap = new Map(); // socketId -> { sessionId, userId }

const addViewer = (sessionId, userId, socketId) => {
  if (!sessionId || !userId || !socketId) return;

  const sid = String(sessionId);
  const uid = String(userId);

  if (!viewers.has(sid)) viewers.set(sid, new Map());
  const userMap = viewers.get(sid);

  if (!userMap.has(uid)) userMap.set(uid, new Set());
  userMap.get(uid).add(socketId);

  socketSessionMap.set(socketId, { sessionId: sid, userId: uid });
};

const removeViewerBySocket = (socketId) => {
  const info = socketSessionMap.get(socketId);
  if (!info) return;

  const { sessionId, userId } = info;
  const userMap = viewers.get(sessionId);

  if (userMap && userMap.has(userId)) {
    userMap.get(userId).delete(socketId);
    if (userMap.get(userId).size === 0) userMap.delete(userId);
  }

  if (userMap && userMap.size === 0) viewers.delete(sessionId);

  socketSessionMap.delete(socketId);
};

const isUserViewingSession = (sessionId, userId) => {
  const userMap = viewers.get(String(sessionId));
  if (!userMap) return false;

  const sockets = userMap.get(String(userId));
  return !!(sockets && sockets.size > 0);
};

module.exports = {
  addViewer,
  removeViewerBySocket,
  isUserViewingSession,
};
