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

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_HelpItem> helpItems = [
      _HelpItem(
        question: "I can't request a ride",
        answer:
        "If you cannot request a ride, first make sure your internet connection is working properly and your current location is turned on. Then check whether your pickup and destination locations are selected correctly. If rides are not showing, there may be no available rider at that moment. You can also try refreshing the app, going back, and searching again. If the problem continues, please report the issue from the Report a Problem section.",
      ),
      _HelpItem(
        question: "Change rider profile picture",
        answer:
        "To change your profile picture, go to your Account or Profile page first. Then tap on your profile picture or the camera icon shown on the profile image area. After that, choose a photo from your gallery and confirm it. Your new profile picture will then be updated.",
      ),
      _HelpItem(
        question: "Update my profile",
        answer:
        "To update your profile, open the Account section and go to your profile page. From there, open the edit or settings related option and update the information you want to change. After making the changes, save the updated details so they appear in your account.",
      ),
      _HelpItem(
        question: "Editing a personal information",
        answer:
        "If you want to edit your personal information, first go to the Account or My Profile section. After that, open the Personal Info option. Inside that page, tap on the Edit button to start changing your information. You can then update the details you need, such as your name, phone number, or other personal information available there. Once you finish editing everything, carefully review the information and then tap the Save button to keep the changes updated in your account.",
      ),
      _HelpItem(
        question: "I would like to know my rating",
        answer:
        "To see your rating, open your Account or Profile page. Your current rating is shown in your profile section. If you are a rider, the rating will reflect the reviews and feedback given through completed trips.",
      ),
      _HelpItem(
        question: "Adding Saved Places",
        answer:
        "To add saved places, go to Account, then open Settings, and select Saved Places. There you can save locations such as Home, Campus, or Hall. You can choose and save these places so that booking future rides becomes faster and easier.",
      ),
      _HelpItem(
        question: "Payment Method",
        answer:
        "To add a payment method, go to your Wallet page from the Account section. Then open Payment Methods and add your preferred payment option, such as bKash. You may need to provide your number and complete the required confirmation steps before it becomes active.",
      ),
      _HelpItem(
        question: "Log out my account",
        answer:
        "If you want to log out of your account, first go to Account, then open Settings. On the Settings page, scroll to the very bottom. There you will find the Log Out option. Tap on it to sign out from your account.",
      ),
      _HelpItem(
        question: "Sign Up as a Rider",
        answer:
        "If you want to sign up as a rider, first go to Account, then open Settings, and select Sign Up as a Rider. After that, choose the type of vehicle you want to use. Then provide the required vehicle details such as vehicle name, model, year, and number plate. You will also need to upload your student ID card photo and the other necessary vehicle-related documents or images required by the app. Once all information is completed and submitted, your rider registration can be reviewed.",
      ),
      _HelpItem(
        question: "Extending expired promotions",
        answer:
        "Expired promotions usually cannot be used again after their validity period ends. If a promotion has expired, you need to wait for a new active offer or promotion to become available in the app. You can check the Promotions or Offers section regularly for new updates.",
      ),
      _HelpItem(
        question: "Suspension to Active account",
        answer:
        "According to app rules, a monthly payment of 30 Taka is required. After one month, a due amount will be shown in your account. If that due is not paid within 7 days, the account will be suspended automatically. To make the account active again, you need to pay the due amount from the Wallet section. Open Account, go to Wallet, check the UniRide Due amount, and complete the payment using your added payment method, such as bKash. Once the payment is successful, the account can become active again.",
      ),
      _HelpItem(
        question: "About Item Send",
        answer:
        "Item Send is for urgent educational items that need to be taken to the university, such as an assignment, research paper, document, notebook, or other study-related materials. If you left an important item at home and need it delivered to the university, you can request this service. While requesting, you need to provide all required details clearly, including sender name, sender phone number, receiver name, receiver phone number, pickup location, drop-off location, and any important item instructions.",
      ),
      _HelpItem(
        question: "About Delivery Item",
        answer:
        "Delivery Item is for carrying important documents or educational materials from the sender to the receiver when it is urgently needed at the university. A rider will collect the item from the sender and deliver it to the receiver. In return, the rider will receive the fixed payment for that delivery, and there may also be an opportunity to pick another ride. This feature is useful for urgent document or study material delivery.",
      ),
      _HelpItem(
        question: "How to reserve a ride",
        answer:
        "To reserve a ride in advance, open the Reserve option in the app. Then choose your destination, select the date and time, and confirm the booking request. Make sure all trip details are correct before confirming.",
      ),
      _HelpItem(
        question: "How to cancel a ride",
        answer:
        "To cancel a ride, go to your current trip or upcoming booking section and open the active ride details. If cancellation is available for that ride, tap the cancel option and confirm it. Cancellation availability may depend on ride status.",
      ),
      _HelpItem(
        question: "Driver or rider did not arrive",
        answer:
        "If the rider or driver did not arrive, first try contacting them if contact information is available in the trip details. If there is still no response, you may cancel the trip if allowed and report the issue through the Report a Problem section.",
      ),
      _HelpItem(
        question: "I forgot something in a ride",
        answer:
        "If you forgot an item in a ride, go to your Ride History and open the relevant trip if that option is available. Then report the issue as soon as possible with details about the lost item so support can review the matter.",
      ),
      _HelpItem(
        question: "How to contact support",
        answer:
        "If you need help, open the Help or Report a Problem section from your account or settings page. Provide clear details about the issue so the support process becomes easier and faster.",
      ),
    ];

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

  _HelpItem({
    required this.question,
    required this.answer,
  });
}