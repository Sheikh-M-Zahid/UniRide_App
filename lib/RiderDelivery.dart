import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderDeliveryPage extends StatefulWidget {
  const RiderDeliveryPage({super.key});

  @override
  State<RiderDeliveryPage> createState() => _RiderDeliveryPageState();
}

class _RiderDeliveryPageState extends State<RiderDeliveryPage> {
  final List<Map<String, dynamic>> deliveryRequests = [
    {
      "senderName": "Rakib Hasan",
      "senderPhone": "01712345678",
      "receiverName": "Nusrat Jahan",
      "receiverPhone": "01811223344",
      "pickup": "Hall Gate",
      "drop": "CSE Building",
      "item": "Document File",
      "fee": "৳60",
      "distance": "2.3 km",
      "time": "10 min",
      "status": "Pending",
    },
    {
      "senderName": "Tamim",
      "senderPhone": "01999888777",
      "receiverName": "Rahim",
      "receiverPhone": "01622334455",
      "pickup": "Library Front",
      "drop": "Main Campus Gate",
      "item": "Calculator",
      "fee": "৳45",
      "distance": "1.8 km",
      "time": "8 min",
      "status": "Pending",
    },
  ];

  Map<String, dynamic>? activeDelivery = {
    "senderName": "Sadia Islam",
    "senderPhone": "01799887766",
    "receiverName": "Farhan",
    "receiverPhone": "01855667788",
    "pickup": "Dormitory Road",
    "drop": "EEE Building",
    "item": "Notebook",
    "fee": "৳50",
    "distance": "2.0 km",
    "time": "9 min",
    "status": "On the way",
  };

  void _acceptDelivery(int index) {
    setState(() {
      activeDelivery = deliveryRequests[index];
      deliveryRequests.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Delivery request accepted"),
      ),
    );
  }

  void _rejectDelivery(int index) {
    setState(() {
      deliveryRequests.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Delivery request rejected"),
      ),
    );
  }

  void _markAsDelivered() {
    setState(() {
      activeDelivery = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Delivery marked as delivered"),
      ),
    );
  }

  Future<void> _callPerson(String name, String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open dial pad for $name"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Delivery Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Delivery Earnings
            Row(
              children: const [
                Expanded(
                  child: _EarningCard(
                    title: "Today Delivery",
                    value: "৳120",
                    icon: Icons.payments_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _EarningCard(
                    title: "This Week",
                    value: "৳540",
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// Active Delivery
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: activeDelivery == null
                  ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Active Delivery",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No active delivery right now",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Active Delivery",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: "Item",
                    value: activeDelivery!["item"],
                  ),
                  _SummaryRow(
                    label: "Pickup",
                    value: activeDelivery!["pickup"],
                  ),
                  _SummaryRow(
                    label: "Drop",
                    value: activeDelivery!["drop"],
                  ),
                  _SummaryRow(
                    label: "Fee",
                    value: activeDelivery!["fee"],
                  ),
                  _SummaryRow(
                    label: "Status",
                    value: activeDelivery!["status"],
                  ),
                  _SummaryRow(
                    label: "Sender",
                    value: activeDelivery!["senderName"] ?? "",
                  ),
                  _SummaryRow(
                    label: "Receiver",
                    value: activeDelivery!["receiverName"] ?? "",
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _markAsDelivered,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Mark as Delivered"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// Contact Option
            if (activeDelivery != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contact Option",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 14),

                    /// Sender
                    _ContactCard(
                      title: "Sender",
                      name: activeDelivery!["senderName"],
                      phone: activeDelivery!["senderPhone"],
                      onCall: () => _callPerson(
                        activeDelivery!["senderName"],
                        activeDelivery!["senderPhone"],
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// Receiver
                    _ContactCard(
                      title: "Receiver",
                      name: activeDelivery!["receiverName"],
                      phone: activeDelivery!["receiverPhone"],
                      onCall: () => _callPerson(
                        activeDelivery!["receiverName"],
                        activeDelivery!["receiverPhone"],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            /// Delivery Requests
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery Requests",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (deliveryRequests.isEmpty)
                    const Text(
                      "No delivery requests available",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    ...List.generate(
                      deliveryRequests.length,
                          (index) {
                        final request = deliveryRequests[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SummaryRow(
                                label: "Item",
                                value: request["item"],
                              ),
                              _SummaryRow(
                                label: "Pickup",
                                value: request["pickup"],
                              ),
                              _SummaryRow(
                                label: "Drop",
                                value: request["drop"],
                              ),
                              _SummaryRow(
                                label: "Distance",
                                value: request["distance"],
                              ),
                              _SummaryRow(
                                label: "Time",
                                value: request["time"],
                              ),
                              _SummaryRow(
                                label: "Fee",
                                value: request["fee"],
                              ),
                              _SummaryRow(
                                label: "Sender",
                                value: request["senderName"],
                              ),
                              _SummaryRow(
                                label: "Receiver",
                                value: request["receiverName"],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _rejectDelivery(index),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text("Reject"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _acceptDelivery(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF14B8A6),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text("Accept"),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _EarningCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final String name;
  final String phone;
  final VoidCallback onCall;

  const _ContactCard({
    required this.title,
    required this.name,
    required this.phone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
            child: const Icon(
              Icons.person,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call, size: 18),
            label: const Text("Call"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 95,
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