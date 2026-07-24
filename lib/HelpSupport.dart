import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

/// ইউজারের বর্তমান একটিভ রোল অনুযায়ী হেল্প আইটেম ফিল্টার করার জন্য।
/// 'both' মানে passenger ও rider উভয়ের জন্যই দেখাবে।
class HelpSupportPage extends StatelessWidget {
  final String userRole; // 'passenger' অথবা 'rider'

  const HelpSupportPage({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final List<_HelpItem> allHelpItems = [
      // ---------------- Passenger: Ride booking ----------------
      _HelpItem(
        question: "I can't request a ride",
        answer:
        "If you cannot request a ride, first make sure your internet connection is working properly and your current location is turned on. Then check whether your pickup and destination locations are selected correctly. If rides are not showing, there may be no available rider at that moment. You can also try refreshing the app, going back, and searching again. If the problem continues, please report the issue from the Report a Problem section.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "How to reserve a ride",
        answer:
        "To reserve a ride in advance, open the Reserve option in the app. Then choose your destination, select the date and time, and confirm the booking request. Make sure all trip details are correct before confirming.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "How to cancel a ride",
        answer:
        "To cancel a ride, go to your current trip or upcoming booking section and open the active ride details. If cancellation is available for that ride, tap the cancel option and confirm it. Cancellation availability may depend on ride status.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "Driver or rider did not arrive",
        answer:
        "If the rider or driver did not arrive, first try contacting them if contact information is available in the trip details. If there is still no response, you may cancel the trip if allowed and report the issue through the Report a Problem section.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "I forgot something in a ride",
        answer:
        "If you forgot an item in a ride, go to your Ride History and open the relevant trip if that option is available. Then report the issue as soon as possible with details about the lost item so support can review the matter.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "Using a promo code",
        answer:
        "To use a promo code, go to the ride booking page and look for the Promo Code option before confirming your ride. Enter a valid promo code there. If it is valid, the discount will be applied automatically and the reduced fare will be shown before you confirm the booking.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "Extending expired promotions",
        answer:
        "Expired promotions usually cannot be used again after their validity period ends. If a promotion has expired, you need to wait for a new active offer or promotion to become available in the app. You can check the Promotions or Offers section regularly for new updates.",
        targetRole: 'passenger',
      ),

      // ---------------- Rider: becoming a rider & requests ----------------
      _HelpItem(
        question: "Sign Up as a Rider",
        answer:
        "If you want to sign up as a rider, first go to Account, then open Settings, and select Sign Up as a Rider. After that, choose the type of vehicle you want to use. Then provide the required vehicle details such as vehicle name, model, year, and number plate. You will also need to upload your student ID card photo and the other necessary vehicle-related documents or images required by the app. Once all information is completed and submitted, your rider registration can be reviewed.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "Viewing and accepting ride requests",
        answer:
        "As a rider, open the Ride Requests page to see all current requests from passengers. Each request is ranked based on factors like distance, matching route, and fare. Tap on a request to view the details, then accept or decline it. Once accepted, the request moves to your active ride.",
        targetRole: 'rider',
      ),
      _HelpItem(
        question: "How ride requests are ranked",
        answer:
        "Ride requests are ranked using a combination of factors such as how close the passenger's pickup point is to you, how well the destination matches your route, current traffic conditions, and the fare amount. Requests with a better overall match are shown higher on the list, along with a rank badge.",
        targetRole: 'rider',
      ),
      _HelpItem(
        question: "Rider earnings and wallet",
        answer:
        "As a rider, your earnings from completed rides and deliveries are added to your Wallet. Open Account, then Wallet, to see your current balance, earnings history, and any wallet bonuses received. You can also see your UniRide Due amount, if any, in the same section.",
        targetRole: 'rider',
      ),

      // ---------------- CoRide ----------------
      _HelpItem(
        question: "How to host a CoRide",
        answer:
        "To host a CoRide, open the CoRide section and submit a ride form with your route, available seats, and timing. Passengers matching your route, gender preference, and occupation (student or faculty) will be able to see and join your ride. You can manage seat availability and see live requests as they come in.",
        targetRole: 'rider',
      ),
      _HelpItem(
        question: "How to join a CoRide",
        answer:
        "To join a CoRide, browse the available CoRide listings that match your route and destination. Select a suitable ride and send a join request. Once the host accepts, you will be able to see live ride details and track the journey.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "Canceling or closing a CoRide",
        answer:
        "If you are a passenger, you can cancel your seat from the active CoRide session before the host starts the journey. If you are the host, you can cancel the ride before starting it, or close the journey once it is completed. Cancellation and closing options may depend on how far the ride has progressed.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Safety check notifications",
        answer:
        "During a ride, you may receive a safety check notification asking you to confirm that everything is fine. Respond to it as soon as possible. If no response is given, the app may notify the admin dashboard for further review. This feature is meant to keep both passengers and riders safe during the trip.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Live map shows 'Reconnecting...'",
        answer:
        "If the live map keeps showing Reconnecting, first check your internet connection. The app automatically retries the connection and refreshes location every few seconds. You can also pull down on the map screen to manually refresh. If the issue continues after a few minutes, please report it through the Report a Problem section.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Navigation during an active ride",
        answer:
        "During an active ride, the app shows in-app navigation with your route drawn on the map, including traffic conditions. If you go off the suggested route, the app will detect the deviation and try to reconnect and update the route automatically.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Booking multiple rides at once",
        answer:
        "You cannot have more than one active ride at the same time, whether it is a standard ride or a CoRide. If you already have an active ride or CoRide session, you will need to complete, cancel, or close it before requesting or accepting another one.",
        targetRole: 'both',
      ),

      // ---------------- Send Item / Delivery ----------------
      _HelpItem(
        question: "About Item Send",
        answer:
        "Item Send is for urgent educational items that need to be taken to the university, such as an assignment, research paper, document, notebook, or other study-related materials. If you left an important item at home and need it delivered to the university, you can request this service. While requesting, you need to provide all required details clearly, including sender name, sender phone number, receiver name, receiver phone number, pickup location, drop-off location, and any important item instructions.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "About Delivery Item",
        answer:
        "Delivery Item is for carrying important documents or educational materials from the sender to the receiver when it is urgently needed at the university. A rider will collect the item from the sender and deliver it to the receiver. In return, the rider will receive the fixed payment for that delivery, and there may also be an opportunity to pick another ride. This feature is useful for urgent document or study material delivery.",
        targetRole: 'rider',
      ),
      _HelpItem(
        question: "Confirming delivery with OTP",
        answer:
        "When a delivery reaches the receiver, a 6-digit OTP is sent to confirm the handover. The OTP is valid for a limited time, so it should be shared with the rider as soon as it is received. Once the correct OTP is entered, the delivery is marked as completed.",
        targetRole: 'both',
      ),

      // ---------------- Account & profile (both) ----------------
      _HelpItem(
        question: "Change profile picture",
        answer:
        "To change your profile picture, go to your Account or Profile page first. Then tap on your profile picture or the camera icon shown on the profile image area. After that, choose a photo from your gallery and confirm it. Your new profile picture will then be updated.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Update my profile",
        answer:
        "To update your profile, open the Account section and go to your profile page. From there, open the edit or settings related option and update the information you want to change. After making the changes, save the updated details so they appear in your account.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Editing personal information",
        answer:
        "If you want to edit your personal information, first go to the Account or My Profile section. After that, open the Personal Info option. Inside that page, tap on the Edit button to start changing your information. You can then update the details you need, such as your name, phone number, or other personal information available there. Once you finish editing everything, carefully review the information and then tap the Save button to keep the changes updated in your account.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "My rating as a passenger",
        answer:
        "To see your rating, open your Account or Profile page. Your passenger rating reflects the feedback given by riders after completed trips.",
        targetRole: 'passenger',
      ),
      _HelpItem(
        question: "My rating as a rider",
        answer:
        "To see your rating, open your Account or Profile page. Your rider rating reflects the feedback given by passengers after completed rides and deliveries.",
        targetRole: 'rider',
      ),
      _HelpItem(
        question: "Adding Saved Places",
        answer:
        "To add saved places, go to Account, then open Settings, and select Saved Places. There you can save locations such as Home, Campus, or Hall. You can choose and save these places so that booking future rides becomes faster and easier.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Payment Method",
        answer:
        "To add a payment method, go to your Wallet page from the Account section. Then open Payment Methods and add your preferred payment option, such as bKash. You may need to provide your number and complete the required confirmation steps before it becomes active.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Log out my account",
        answer:
        "If you want to log out of your account, first go to Account, then open Settings. On the Settings page, scroll to the very bottom. There you will find the Log Out option. Tap on it to sign out from your account.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "Suspension to Active account",
        answer:
        "According to app rules, a monthly payment of 30 Taka is required. After one month, a due amount will be shown in your account. If that due is not paid within 7 days, the account will be suspended automatically. To make the account active again, you need to pay the due amount from the Wallet section. Open Account, go to Wallet, check the UniRide Due amount, and complete the payment using your added payment method, such as bKash. Once the payment is successful, the account can become active again.",
        targetRole: 'both',
      ),
      _HelpItem(
        question: "How to contact support",
        answer:
        "If you need help, open the Help or Report a Problem section from your account or settings page. Provide clear details about the issue so the support process becomes easier and faster.",
        targetRole: 'both',
      ),
    ];

    final List<_HelpItem> helpItems = allHelpItems
        .where((item) => item.targetRole == 'both' || item.targetRole == userRole)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          "Help",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "How can we help you?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Tap any question below to see the answer.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: helpItems.length,
              itemBuilder: (context, index) {
                final item = helpItems[index];
                return _HelpExpansionTile(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpExpansionTile extends StatefulWidget {
  final _HelpItem item;

  const _HelpExpansionTile({
    required this.item,
  });

  @override
  State<_HelpExpansionTile> createState() => _HelpExpansionTileState();
}

class _HelpExpansionTileState extends State<_HelpExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _isExpanded ? AppColors.primary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.mutedText,
          title: Text(
            widget.item.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _isExpanded ? AppColors.primary : AppColors.text,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.item.answer,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;
  final String targetRole; // 'passenger', 'rider', অথবা 'both'

  _HelpItem({
    required this.question,
    required this.answer,
    required this.targetRole,
  });
}