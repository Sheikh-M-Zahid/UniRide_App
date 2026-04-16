import 'package:flutter/material.dart';
import 'UserActivity.dart';
import 'UserProfile.dart';
import 'UserOffer.dart';
import 'UserHome.dart';
import 'RideSearch.dart';
import 'ReserveRide.dart';
import 'SendItem.dart';
import 'SharingCaringPage.dart';
import 'services/auth_api_service.dart';

void main() {
  runApp(const UberCloneApp());
}

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class UberCloneApp extends StatelessWidget {
  const UberCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ServicesPage(),
    );
  }
}

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  String selectedCategory = 'All';
  bool hasAdminOffer = false;
  String adminOfferTitle = '';
  String adminOfferSubtitle = '';
  bool isLoadingServicesSummary = true;

  final List<String> categories = const [
    'All',
    'Ride',
    'Reserve',
    'Delivery',
    'Community',
  ];

  @override
  void initState() {
    super.initState();
    _loadServicesSummary();
  }

  Future<void> _loadServicesSummary() async {
    try {
      final response = await _authApiService.getServicesSummary();
      final data = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        hasAdminOffer = data['hasAdminOffer'] == true;
        adminOfferTitle = data['offerTitle']?.toString() ?? '';
        adminOfferSubtitle = data['offerSubtitle']?.toString() ?? '';
        isLoadingServicesSummary = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        hasAdminOffer = false;
        adminOfferTitle = '';
        adminOfferSubtitle = '';
        isLoadingServicesSummary = false;
      });
    }
  }

  List<_ServiceItem> get allServices => [
    _ServiceItem(
      title: 'Car',
      icon: Icons.directions_car,
      category: 'Ride',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanYourRidePage(
              googleApiKey: 'YOUR_GOOGLE_API_KEY',
            ),
          ),
        );
      },
    ),
    _ServiceItem(
      title: 'Bike',
      icon: Icons.pedal_bike,
      category: 'Ride',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanYourRidePage(
              googleApiKey: 'YOUR_GOOGLE_API_KEY',
            ),
          ),
        );
      },
    ),
    _ServiceItem(
      title: 'Reserve',
      icon: Icons.calendar_month,
      category: 'Reserve',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReserveRide(),
          ),
        );
      },
    ),
    _ServiceItem(
      title: 'Send Item',
      icon: Icons.inventory_2_outlined,
      category: 'Delivery',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SendItemForm(),
          ),
        );
      },
    ),
    _ServiceItem(
      title: 'Co Ride',
      icon: Icons.volunteer_activism,
      category: 'Community',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SharingCaringPage(),
          ),
        );
      },
    ),
    _ServiceItem(
      title: 'Alumni',
      icon: Icons.school_outlined,
      category: 'Community',
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alumni feature will be added soon'),
          ),
        );
      },
    ),
  ];

  List<_ServiceItem> get filteredServices {
    final query = _searchController.text.trim().toLowerCase();

    return allServices.where((service) {
      final matchesCategory =
          selectedCategory == 'All' || service.category == selectedCategory;
      final matchesSearch = query.isEmpty ||
          service.title.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Go anywhere, get anything',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedText,
                ),
              ),

              const SizedBox(height: 20),

              _buildTopSearchBar(),

              const SizedBox(height: 18),

              _buildCategorySection(),

              const SizedBox(height: 18),

              if (hasAdminOffer) ...[
                _buildOfferBanner(),
                const SizedBox(height: 18),
              ],

              const Text(
                'Available Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double cardWidth;

                    if (constraints.maxWidth >= 1000) {
                      cardWidth = (constraints.maxWidth - 60) / 4;
                    } else if (constraints.maxWidth >= 700) {
                      cardWidth = (constraints.maxWidth - 24) / 3;
                    } else {
                      cardWidth = (constraints.maxWidth - 12) / 2;
                    }

                    cardWidth = cardWidth.clamp(145.0, 220.0);

                    final services = filteredServices;

                    if (services.isEmpty) {
                      return const Center(
                        child: Text(
                          'No services found',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: services.map((service) {
                          return _AnimatedServiceCard(
                            title: service.title,
                            icon: service.icon,
                            width: cardWidth,
                            subtitle: service.category,
                            onTap: service.onTap,
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedText,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UniRideHomePage(),
                ),
              );
              break;

            case 1:
              break;

            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivityPage(),
                ),
              );
              break;

            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OffersPage(),
                ),
              );
              break;

            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UniRideProfilePage(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
        },
        decoration: const InputDecoration(
          hintText: 'Search services',
          hintStyle: TextStyle(
            color: AppColors.mutedText,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.secondary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OffersPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adminOfferTitle.isNotEmpty
                        ? adminOfferTitle
                        : 'Special Offer Available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    adminOfferSubtitle.isNotEmpty
                        ? adminOfferSubtitle
                        : 'Tap to view and claim your latest campus deal',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedServiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double width;
  final VoidCallback onTap;

  const _AnimatedServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.width,
    required this.onTap,
  });

  @override
  State<_AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<_AnimatedServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.97 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: widget.width,
        height: 118,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.06 : 0.10),
              blurRadius: _pressed ? 4 : 8,
              offset: Offset(0, _pressed ? 2 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            onHighlightChanged: (value) {
              setState(() {
                _pressed = value;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 34,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String category;
  final IconData icon;
  final VoidCallback onTap;

  _ServiceItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.onTap,
  });
}