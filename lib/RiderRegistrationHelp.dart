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

class RiderRegistrationHelpPage extends StatelessWidget {
  const RiderRegistrationHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_HelpSection> helpSections = [
      _HelpSection(
        title: "About Rider Registration",
        items: [
          _HelpItem(
            question: "What is this page for?",
            answer:
            "This page explains how to complete rider registration correctly. If you face any confusion while filling up the bike or car registration form, you can read the instructions here and continue your registration easily.",
          ),
          _HelpItem(
            question: "Will I get rider access immediately after submitting?",
            answer:
            "No. After submitting your rider registration, your documents and vehicle information will go to the admin for verification. You will get rider access only after the admin approves your request.",
          ),
        ],
      ),
      _HelpSection(
        title: "Bike Registration Help",
        items: [
          _HelpItem(
            question: "How do I register a bike?",
            answer:
            "First select your bike brand. Then select your model, year, and enter your number plate. After that, upload all required documents such as Varsity ID card, profile photo, driving license, vehicle registration, and tax token. Finally, tap the Continue button to submit your registration.",
          ),
          _HelpItem(
            question: "My bike brand is not in the list. What should I do?",
            answer:
            "If your bike brand is not available in the list, select Others. Then write your bike brand manually in the text field that appears.",
          ),
          _HelpItem(
            question: "My bike model is not in the list. What should I do?",
            answer:
            "If your bike model is not available, select Others from the model list. Then write your correct bike model manually.",
          ),
        ],
      ),
      _HelpSection(
        title: "Private Car Registration Help",
        items: [
          _HelpItem(
            question: "How do I register a private car?",
            answer:
            "First select your car make, model, and year. Then enter your number plate. After that, upload all required documents such as Varsity ID card, profile photo, driving license, vehicle registration, and tax token. Finally, tap Continue to submit the request.",
          ),
          _HelpItem(
            question: "My car brand is not in the list. What should I do?",
            answer:
            "If your car brand is not listed, select Others. Then write your car brand manually in the field shown below.",
          ),
          _HelpItem(
            question: "My car model is not in the list. What should I do?",
            answer:
            "If your model is not listed, select Others from the model dropdown. Then write the correct model manually.",
          ),
        ],
      ),
      _HelpSection(
        title: "Number Plate Format",
        items: [
          _HelpItem(
            question: "How should I write my number plate?",
            answer:
            "Write your number plate in Bangladesh English format, for example: DHA-Metro-Ga-11-1234. Make sure the format is correct and do not leave unnecessary spaces.",
          ),
          _HelpItem(
            question: "If I write the wrong number plate, what can happen?",
            answer:
            "If the number plate is incorrect, your registration may be rejected during verification. Always enter the exact number plate shown on your vehicle registration documents.",
          ),
        ],
      ),
      _HelpSection(
        title: "Required Documents",
        items: [
          _HelpItem(
            question: "Which documents must I upload?",
            answer:
            "You must upload Varsity ID card, profile photo, driving license, vehicle registration paper, and tax token. All required files should be clear and readable.",
          ),
          _HelpItem(
            question: "Can I submit registration without all documents?",
            answer:
            "No. Registration will not be complete without all required documents.",
          ),
          _HelpItem(
            question: "What type of profile photo should I upload?",
            answer:
            "Upload a clear and recent profile photo where your face is visible properly. Avoid blurry, dark, or cropped photos.",
          ),
          _HelpItem(
            question: "What happens if my document image is blurry?",
            answer:
            "If any uploaded document is unclear, the admin may reject your request. Make sure every image is readable before submitting.",
          ),
        ],
      ),
      _HelpSection(
        title: "Submission and Verification",
        items: [
          _HelpItem(
            question: "What happens after submission?",
            answer:
            "After submission, your request will stay in pending status until the admin reviews it. During that time, you may need to wait for approval.",
          ),
          _HelpItem(
            question: "What does Pending mean?",
            answer:
            "Pending means your rider registration request has been submitted successfully, but the admin has not reviewed it yet.",
          ),
          _HelpItem(
            question: "What does Approved mean?",
            answer:
            "Approved means your registration is accepted and you can use rider-related features.",
          ),
          _HelpItem(
            question: "What does Rejected mean?",
            answer:
            "Rejected means there was a problem with your submitted information or documents. You may need to correct them and submit again.",
          ),
        ],
      ),
      _HelpSection(
        title: "Common Questions",
        items: [
          _HelpItem(
            question: "Can I use someone else's documents?",
            answer:
            "No. You must use your own valid documents and correct vehicle information.",
          ),
          _HelpItem(
            question: "Can I submit fake or edited documents?",
            answer:
            "No. Fake, edited, or incorrect documents may cause rejection and may lead to account-related action later.",
          ),
          _HelpItem(
            question: "Can the same number plate be used more than once?",
            answer:
            "No. A duplicate number plate cannot be registered again.",
          ),
          _HelpItem(
            question: "I submitted the wrong information. What should I do?",
            answer:
            "If your request is still pending, wait for the verification result. If it gets rejected, correct the information and submit again properly.",
          ),
        ],
      ),
      _HelpSection(
        title: "Need More Help?",
        items: [
          _HelpItem(
            question: "I still need help. What should I do?",
            answer:
            "If you still face any confusion, go back and carefully review each field before submitting. You can also use the main Help or Report a Problem option in the app to contact support.",
          ),
        ],
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
          "Rider Registration Help",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 21,
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
                  "How to register as a rider",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Tap any question below to see the answer. This page will help you complete bike or car registration correctly.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: helpSections.length,
              itemBuilder: (context, sectionIndex) {
                final section = helpSections[sectionIndex];
                return _HelpSectionCard(section: section);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSectionCard extends StatelessWidget {
  final _HelpSection section;

  const _HelpSectionCard({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          ...section.items.map((item) => _HelpExpansionTile(item: item)),
        ],
      ),
    );
  }
}

class _HelpExpansionTile extends StatelessWidget {
  final _HelpItem item;

  const _HelpExpansionTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.mutedText,
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection {
  final String title;
  final List<_HelpItem> items;

  _HelpSection({
    required this.title,
    required this.items,
  });
}

class _HelpItem {
  final String question;
  final String answer;

  _HelpItem({
    required this.question,
    required this.answer,
  });
}