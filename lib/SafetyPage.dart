import 'package:flutter/material.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final Color primaryColor = const Color(0xFF14B8A6);
  final Color secondaryColor = const Color(0xFF0F766E);
  final Color backgroundColor = const Color(0xFFF9FAFB);
  final Color textColor = const Color(0xFF1F2937);

  final List<bool> _isExpanded = [true, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        centerTitle: true,
        title: Text(
          'Safety',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBanner(),
              const SizedBox(height: 20),

              _buildExpandableCard(
                index: 0,
                title: 'Safety tips',
                subtitle: 'Ride with confidence with UniRide’s safety tools and tips.',
                content: _buildSafetyTipsContent(),
              ),

              const SizedBox(height: 14),

              _buildExpandableCard(
                index: 1,
                title: 'Safety at UniRide',
                subtitle: 'Understand how UniRide stands for your safety.',
                content: _buildSafetyAtUniRideContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.12),
            secondaryColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: secondaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your safety matters',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'UniRide is designed to help students, teachers, and staff ride more safely, confidently, and comfortably within the university community.',
                  style: TextStyle(
                    color: textColor.withOpacity(0.78),
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCard({
    required int index,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    final bool expanded = _isExpanded[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expanded
              ? primaryColor.withOpacity(0.35)
              : Colors.grey.withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _isExpanded[index] = !_isExpanded[index];
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      index == 0
                          ? Icons.health_and_safety_rounded
                          : Icons.shield_rounded,
                      color: secondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: textColor.withOpacity(0.72),
                            fontSize: 14.2,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 30,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: content,
            ),
            crossFadeState:
            expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ride with confidence'),
        _paragraph(
          'UniRide is designed with safety in mind. Through trip tools, account visibility, in-app support options, and community-focused policies, we aim to help you move more safely within your university environment.',
        ),
        const SizedBox(height: 16),

        _featureTile(
          icon: Icons.emergency_rounded,
          title: 'Emergency assistance',
          description:
          'Users can quickly access emergency help options from the app during a trip if they feel unsafe or need urgent assistance.',
        ),
        _featureTile(
          icon: Icons.support_agent_rounded,
          title: 'Incident support',
          description:
          'If something unexpected happens, users can report the issue through the app so that the UniRide admin team can review it and take action.',
        ),
        _featureTile(
          icon: Icons.share_location_rounded,
          title: 'Share trip details',
          description:
          'Trip details can be shared with a trusted person so someone else knows your route and ride status.',
        ),
        _featureTile(
          icon: Icons.security_rounded,
          title: 'Safety center',
          description:
          'Safety-related tools and important guidance can be kept in one place so they are easy to find during a ride.',
        ),
        _featureTile(
          icon: Icons.star_rate_rounded,
          title: '2-way ratings',
          description:
          'Both sides can give feedback after a trip. This helps identify unsafe behavior and improves trust on the platform.',
        ),
        _featureTile(
          icon: Icons.gps_fixed_rounded,
          title: 'GPS tracking',
          description:
          'Trips can be tracked from pickup to destination to improve route visibility and accountability.',
        ),

        const SizedBox(height: 18),
        _sectionTitle('Check your ride, every time'),
        _paragraph(
          'Before starting a trip, users should always confirm ride details shown in the app.',
        ),
        const SizedBox(height: 10),

        _stepTile(
          number: '1',
          title: 'Match the vehicle number',
          description:
          'Check that the number plate shown in the app matches the actual vehicle.',
        ),
        _stepTile(
          number: '2',
          title: 'Match the vehicle details',
          description:
          'Confirm the car or bike brand, model, and other visible details before you begin the trip.',
        ),
        _stepTile(
          number: '3',
          title: 'Check the profile information',
          description:
          'Make sure the driver or rider information in the app matches the person you are meeting.',
        ),

        const SizedBox(height: 18),
        _sectionTitle('Community first'),
        _paragraph(
          'UniRide is intended for a university-only community. Respectful behavior, clear communication, and responsible use of the app are essential for a safer experience for everyone.',
        ),
      ],
    );
  }

  Widget _buildSafetyAtUniRideContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Understand how UniRide stands for your safety'),
        _paragraph(
          'UniRide is being designed as a university-focused ride-sharing platform where students, teachers, and staff can connect more safely inside one trusted system. Since the app has not launched yet, the features below describe how UniRide is planned to support user safety.',
        ),

        const SizedBox(height: 18),

        _infoCard(
          icon: Icons.verified_user_outlined,
          title: 'University-only community',
          description:
          'Only verified students, teachers, and staff will be part of the UniRide ecosystem. This helps create a more controlled and trusted ride-sharing environment than open public platforms.',
        ),

        _infoCard(
          icon: Icons.people_alt_outlined,
          title: 'One app, connected roles',
          description:
          'Rider, passenger, and admin features will exist within the same app environment. This makes communication, trip review, reporting, and safety management more organized and easier to control.',
        ),

        _infoCard(
          icon: Icons.female_outlined,
          title: 'Gender preference support',
          description:
          'UniRide includes a gender preference option. If a user selects a gender preference for a ride, only users from that selected gender should be able to join or match for that ride. This is especially important for comfort and safety in shared ride situations.',
        ),

        _infoCard(
          icon: Icons.directions_car_filled_outlined,
          title: 'Sharing Caring option',
          description:
          'In the Sharing Caring feature, a user may arrange an outside vehicle and share the trip with another person going in the same direction. In this case, gender preference becomes even more important, because it helps ensure that only the preferred gender can request to join that trip.',
        ),

        _infoCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'In-app messaging after acceptance',
          description:
          'If someone sends a ride request and the request is accepted, a message option will be activated between both users. They can then communicate inside the app to confirm location, time, route, and other important ride details before the trip starts.',
        ),

        _infoCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admin visibility and control',
          description:
          'Because the admin system exists inside the same platform, safety-related reports, suspicious activity, or user complaints can be reviewed more directly. This adds another layer of accountability within the UniRide community.',
        ),

        _infoCard(
          icon: Icons.route_outlined,
          title: 'Trip clarity before ride start',
          description:
          'Important trip details such as who is joining, where the ride starts, where it ends, and whether the ride is private or shared should be visible in the app so users can make informed decisions before confirming.',
        ),

        _infoCard(
          icon: Icons.flag_outlined,
          title: 'Reporting and feedback',
          description:
          'Users should be able to report uncomfortable behavior, cancel when needed, and leave feedback after a trip. This supports long-term trust and helps the platform identify misuse early.',
        ),

        _infoCard(
          icon: Icons.lock_outline_rounded,
          title: 'Safer communication and privacy',
          description:
          'Keeping communication inside the app is better than relying on external messaging from the beginning. It helps maintain privacy, keeps the conversation relevant to the trip, and supports safer coordination between users.',
        ),

        const SizedBox(height: 18),
        _highlightBox(
          'Why this matters',
          'UniRide is not just a ride-sharing app. It is a campus-focused transport community. By combining verified university users, gender preference, shared-trip control, in-app messaging, and admin oversight, UniRide can create a safer and more comfortable experience for everyone.',
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(
          color: textColor.withOpacity(0.82),
          fontSize: 14.8,
          height: 1.65,
        ),
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: secondaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: textColor.withOpacity(0.74),
                      fontSize: 13.8,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTile({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 34,
              width: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: textColor.withOpacity(0.74),
                      fontSize: 13.8,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.withOpacity(0.10),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: secondaryColor, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: textColor.withOpacity(0.78),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightBox(String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}