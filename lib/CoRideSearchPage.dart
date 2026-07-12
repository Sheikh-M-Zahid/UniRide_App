import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/auth_api_service.dart';
import 'map_picker_screen.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color border = Color(0xFFE5E7EB);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color softPrimary = Color(0xFFECFEFF);
}

class CoRideSearchPage extends StatefulWidget {
  const CoRideSearchPage({super.key});

  @override
  State<CoRideSearchPage> createState() => _CoRideSearchPageState();
}

class _CoRideSearchPageState extends State<CoRideSearchPage> {
  final AuthApiService _api = AuthApiService();

  LatLng? pickupLatLng;
  LatLng? destinationLatLng;
  String pickupAddress = '';
  String destinationAddress = '';

  bool isSearching = false;
  bool hasSearched = false;
  List<dynamic> results = [];

  static const LatLng _fallback = LatLng(23.8103, 90.4125);

  Future<void> _pickPickup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialPosition: pickupLatLng ?? _fallback,
          title: "Select Pickup Location",
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        pickupAddress = result["address"] ?? "";
        pickupLatLng = result["latLng"];
      });
    }
  }

  Future<void> _pickDestination() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialPosition: destinationLatLng ?? pickupLatLng ?? _fallback,
          title: "Select Destination",
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        destinationAddress = result["address"] ?? "";
        destinationLatLng = result["latLng"];
      });
    }
  }

  Future<void> _search() async {
    if (pickupLatLng == null || destinationLatLng == null) return;

    setState(() {
      isSearching = true;
      hasSearched = true;
    });

    try {
      final response = await _api.searchCoRideSessions(
        pickupLat: pickupLatLng!.latitude,
        pickupLng: pickupLatLng!.longitude,
        destinationLat: destinationLatLng!.latitude,
        destinationLng: destinationLatLng!.longitude,
      );
      setState(() {
        results = response['data'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  Future<void> _bookSession(String sessionId) async {
    try {
      await _api.bookCoRideSession(sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = pickupLatLng != null && destinationLatLng != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Find a CoRide", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLocationTile(
                  icon: Icons.my_location_rounded,
                  label: "Pickup",
                  value: pickupAddress.isEmpty ? "Select pickup location" : pickupAddress,
                  onTap: _pickPickup,
                ),
                const SizedBox(height: 12),
                _buildLocationTile(
                  icon: Icons.location_on_rounded,
                  label: "Destination",
                  value: destinationAddress.isEmpty ? "Select destination" : destinationAddress,
                  onTap: _pickDestination,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (canSearch && !isSearching) ? _search : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSearching
                        ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text("Search", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: !hasSearched
                ? const Center(
              child: Text(
                "Pick pickup and destination to search for CoRide.",
                style: TextStyle(color: AppColors.mutedText),
              ),
            )
                : results.isEmpty
                ? const Center(
              child: Text(
                "No matching CoRide found on this route right now.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) => _buildResultCard(results[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.softPrimary,
              child: Icon(icon, size: 18, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 4),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(dynamic session) {
    final name = '${session['first_name'] ?? ''} ${session['last_name'] ?? ''}'.trim();
    final isFrequent = session['isFrequentPartner'] == true;
    final score = (session['coRideScore'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name.isEmpty ? 'Rider' : name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              if (isFrequent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text('তোমার নিয়মিত সঙ্গী',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309), fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${session['start_location']} → ${session['destination']}',
              style: const TextStyle(fontSize: 13, color: AppColors.text)),
          const SizedBox(height: 6),
          Text('Fare: ৳${session['fare_per_person'] ?? 'N/A'} · Seats left: ${session['available_seats'] ?? 0}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _bookSession(session['session_id'].toString()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}