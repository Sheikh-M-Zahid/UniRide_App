import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class RegisteredVehiclesPage extends StatefulWidget {
  const RegisteredVehiclesPage({super.key});

  @override
  State<RegisteredVehiclesPage> createState() => _RegisteredVehiclesPageState();
}

class _RegisteredVehiclesPageState extends State<RegisteredVehiclesPage> {
  final AuthApiService _authApiService = AuthApiService();

  List<Map<String, dynamic>> registeredVehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final response = await _authApiService.getMyVehicles();
      final data = response['data'];

      List<Map<String, dynamic>> vehicles = [];

      if (data is List) {
        vehicles = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['vehicles'] is List) {
        vehicles = List<Map<String, dynamic>>.from(data['vehicles']);
      }

      if (!mounted) return;

      setState(() {
        registeredVehicles = vehicles;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openVehicleDocuments(Map<String, dynamic> vehicle) async {
    final vehicleId =
    (vehicle['vehicleId'] ?? vehicle['vehicle_id'] ?? vehicle['id'] ?? '')
        .toString();

    if (vehicleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle ID not found'),
        ),
      );
      return;
    }

    try {
      final response = await _authApiService.getVehicleDocuments(
        vehicleId: vehicleId,
      );

      final data = response['data'];
      List<Map<String, dynamic>> documents = [];

      if (data is List) {
        documents = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['documents'] is List) {
        documents = List<Map<String, dynamic>>.from(data['documents']);
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleDocumentsPage(
            vehicleName:
            "${(vehicle['company'] ?? vehicle['brand'] ?? '').toString()} ${(vehicle['model'] ?? '').toString()}",
            documents: documents,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  IconData _vehicleIcon(Map<String, dynamic> vehicle) {
    final String brand = (vehicle["brand"] ?? "").toString().toLowerCase();
    final String model = (vehicle["model"] ?? "").toString().toLowerCase();

    final String combined = "$brand $model";

    if (combined.contains("yamaha") ||
        combined.contains("honda") ||
        combined.contains("suzuki") ||
        combined.contains("bike") ||
        combined.contains("motorcycle") ||
        combined.contains("r15") ||
        combined.contains("hornet") ||
        combined.contains("gixxer") ||
        combined.contains("fzs") ||
        combined.contains("cbr") ||
        combined.contains("pulsar")) {
      return Icons.directions_bike;
    }

    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Registered Vehicles",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: const BackButton(color: Color(0xFF1F2937)),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF14B8A6),
        ),
      )
          : registeredVehicles.isEmpty
          ? const Center(
        child: Text(
          "No registered vehicle found",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: registeredVehicles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final vehicle = registeredVehicles[index];

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FFFB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _vehicleIcon(vehicle),
                        color: const Color(0xFF0F766E),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "${(vehicle["company"] ?? vehicle["brand"] ?? "").toString()} ${(vehicle["model"] ?? "").toString()}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _vehicleInfoRow(
                  "Brand",
                  (vehicle["company"] ?? vehicle["brand"] ?? "").toString(),
                ),
                _vehicleInfoRow(
                  "Model",
                  (vehicle["model"] ?? "").toString(),
                ),
                _vehicleInfoRow(
                  "Year",
                  (vehicle["year"] ?? "").toString(),
                ),
                _vehicleInfoRow(
                  "Number Plate",
                  (vehicle["number_plate"] ?? vehicle["numberPlate"] ?? "")
                      .toString(),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openVehicleDocuments(vehicle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "View Documents",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _vehicleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleDocumentsPage extends StatelessWidget {
  final String vehicleName;
  final List<Map<String, dynamic>> documents;

  const VehicleDocumentsPage({
    super.key,
    required this.vehicleName,
    required this.documents,
  });

  Color _statusColor(String status) {
    if (status.toLowerCase() == "verified") {
      return const Color(0xFF0F766E);
    }
    if (status.toLowerCase() == "pending") {
      return Colors.orange;
    }
    return Colors.red;
  }

  IconData _documentIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains("license")) return Icons.badge_outlined;
    if (lower.contains("registration")) return Icons.description_outlined;
    if (lower.contains("tax")) return Icons.receipt_long_outlined;
    if (lower.contains("photo")) return Icons.photo_outlined;
    if (lower.contains("id")) return Icons.credit_card_outlined;

    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          vehicleName,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: const BackButton(color: Color(0xFF1F2937)),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
      ),
      body: documents.isEmpty
          ? const Center(
        child: Text(
          "No documents found",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final doc = documents[index];
          final String status =
          (doc["status"] ?? "Unknown").toString();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _documentIcon(doc["title"] ?? ""),
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (doc["title"] ?? doc["name"] ?? "").toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "File: ${(doc["fileUrl"] ?? doc["file_url"] ?? doc["url"] ?? doc["path"] ?? "").toString()}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}