import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class AddOfferPage extends StatefulWidget {
  const AddOfferPage({super.key});

  @override
  State<AddOfferPage> createState() => _AddOfferPageState();
}

class _AddOfferPageState extends State<AddOfferPage> {
  final AuthApiService _authApiService = AuthApiService();
  bool isSubmitting = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController offerNameController = TextEditingController();
  final TextEditingController rewardController = TextEditingController();
  final TextEditingController promoController = TextEditingController();
  final TextEditingController conditionController = TextEditingController();

  String? selectedOfferType;
  String? selectedTarget;

  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> activeOffers = [];

  final List<String> offerTypes = [
    "Ride Discount",
    "Cashback",
    "Festival Offer",
    "Referral Bonus",
  ];

  final List<String> targetUsers = [
    "Rider",
    "Passenger",
    "Both",
  ];

  final List<String> offerCategories = ["Normal", "Bonus"];

  final List<String> usageLimitTypes = [
    "Once Per User",
    "Once Per Day",
    "Unlimited",
  ];

  final List<String> conditionTypes = [
    "None",
    "Min Rides Per Month",
    "Min Items Per Month",
    "Min Fare Amount",
    "New User Only",
  ];

  final List<String> rideTypes = ["Both", "Ride", "Send Item"];

  String? selectedOfferCategory;
  String? selectedUsageLimitType;
  String? selectedConditionType;
  String? selectedRideType;

  final TextEditingController conditionValueController = TextEditingController();
  final TextEditingController maxTotalUsesController = TextEditingController();

  bool get isFormValid {
    final bonusValid = selectedOfferCategory != 'Bonus' ||
        maxTotalUsesController.text.isNotEmpty;
    final conditionValid = selectedConditionType == 'None' ||
        selectedConditionType == 'New User Only' ||
        selectedConditionType == null ||
        conditionValueController.text.isNotEmpty;

    return offerNameController.text.isNotEmpty &&
        rewardController.text.isNotEmpty &&
        selectedOfferType != null &&
        selectedTarget != null &&
        selectedOfferCategory != null &&
        selectedUsageLimitType != null &&
        selectedConditionType != null &&
        selectedRideType != null &&
        startDate != null &&
        endDate != null &&
        promoController.text.isNotEmpty &&
        bonusValid &&
        conditionValid;
  }

  Future<void> pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Future<void> addOffer() async {
    if (!isFormValid) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await _authApiService.createOffer(
        offerName: offerNameController.text.trim(),
        offerType: selectedOfferType!.trim(),
        offerCategory: selectedOfferCategory!.toLowerCase(),
        rewardPercentage: rewardController.text.trim(),
        eligibleUser: selectedTarget!.trim(),
        startDate: startDate!.toIso8601String().split('T').first,
        endDate: endDate!.toIso8601String().split('T').first,
        promoCode: promoController.text.trim(),
        conditions: conditionController.text.trim(),
        usageLimitType: selectedUsageLimitType!
            .toLowerCase()
            .replaceAll(' ', '_'),
        conditionType: selectedConditionType!
            .toLowerCase()
            .replaceAll(' ', '_'),
        conditionValue: conditionValueController.text.isNotEmpty
            ? int.tryParse(conditionValueController.text.trim())
            : null,
        eligibleRideType: selectedRideType!
            .toLowerCase()
            .replaceAll(' ', '_'),
        maxTotalUses: selectedOfferCategory == 'Bonus' &&
            maxTotalUsesController.text.isNotEmpty
            ? int.tryParse(maxTotalUsesController.text.trim())
            : null,
      );

      final data = response['data'] ?? {};

      final Map<String, dynamic> newOffer = {
        "name": data["offer_name"] ?? offerNameController.text.trim(),
        "type": data["offer_type"] ?? selectedOfferType,
        "reward": data["reward_percentage"]?.toString() ?? rewardController.text.trim(),
        "target": data["eligible_user"] ?? selectedTarget,
        "start": DateTime.tryParse((data["start_date"] ?? '').toString()) ?? startDate,
        "end": DateTime.tryParse((data["end_date"] ?? '').toString()) ?? endDate,
        "promo": data["promo_code"] ?? promoController.text.trim(),
        "condition": data["conditions"] ?? conditionController.text.trim(),
      };

      setState(() {
        activeOffers.insert(0, newOffer);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offer added successfully")),
      );

      offerNameController.clear();
      rewardController.clear();
      promoController.clear();
      conditionController.clear();
      selectedOfferType = null;
      selectedTarget = null;
      startDate = null;
      endDate = null;

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add offer: $e")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          glassBox(
            Column(
              children: [

                const Text(
                  "Add New Offer",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 25),

                buildTextField("Offer Name", offerNameController),

                const SizedBox(height: 15),

                buildDropdown(
                  "Offer Type",
                  selectedOfferType,
                  offerTypes,
                      (val) => setState(() => selectedOfferType = val),
                ),

                const SizedBox(height: 15),

                buildTextField("Reward Percentage (%)", rewardController,
                    isNumber: true),

                const SizedBox(height: 15),

                buildDropdown(
                  "Target User",
                  selectedTarget,
                  targetUsers,
                      (val) => setState(() => selectedTarget = val),
                ),

                const SizedBox(height: 15),

                buildDropdown(
                  "Offer Category",
                  selectedOfferCategory,
                  offerCategories,
                      (val) => setState(() => selectedOfferCategory = val),
                ),

                const SizedBox(height: 15),

                buildDropdown(
                  "Usage Limit",
                  selectedUsageLimitType,
                  usageLimitTypes,
                      (val) => setState(() => selectedUsageLimitType = val),
                ),

                const SizedBox(height: 15),

                buildDropdown(
                  "Applicable For",
                  selectedRideType,
                  rideTypes,
                      (val) => setState(() => selectedRideType = val),
                ),

                const SizedBox(height: 15),

                buildDropdown(
                  "Condition Type",
                  selectedConditionType,
                  conditionTypes,
                      (val) => setState(() => selectedConditionType = val),
                ),

                if (selectedConditionType != null &&
                    selectedConditionType != 'None' &&
                    selectedConditionType != 'New User Only') ...[
                  const SizedBox(height: 15),
                  buildTextField(
                    "Condition Value (number)",
                    conditionValueController,
                    isNumber: true,
                  ),
                ],

                if (selectedOfferCategory == 'Bonus') ...[
                  const SizedBox(height: 15),
                  buildTextField(
                    "Max Total Uses",
                    maxTotalUsesController,
                    isNumber: true,
                  ),
                ],

                const SizedBox(height: 15),

                dateTile("Start Date", startDate, pickStartDate),
                const SizedBox(height: 10),
                dateTile("End Date", endDate, pickEndDate),

                const SizedBox(height: 15),

                buildTextField("Promo Code", promoController),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isFormValid ? Colors.cyanAccent : Colors.grey,
                    ),
                    onPressed: (isFormValid && !isSubmitting) ? addOffer : null,
                    child: const Text(
                      "Confirm & Activate Offer",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================= Active Offers =================

          if (activeOffers.isNotEmpty)
            glassBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Active Offers",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...activeOffers.map((offer) => offerCard(offer)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget glassBox(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.cyanAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.black87,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child:
        Text(e, style: const TextStyle(color: Colors.white)),
      ))
          .toList(),
      onChanged: (val) {
        onChanged(val);
        setState(() {});
      },
    );
  }

  Widget dateTile(String title, DateTime? date, VoidCallback onTap) {
    return ListTile(
      shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(10)),
      title: Text(
        date == null
            ? title
            : "${date.day}-${date.month}-${date.year}",
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.calendar_today, color: Colors.white),
      onTap: onTap,
    );
  }

  Widget offerCard(Map offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer["name"],
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold)),
          Text("Promo: ${offer["promo"]}",
              style: const TextStyle(color: Colors.white)),
          Text("Target: ${offer["target"]}",
              style: const TextStyle(color: Colors.white70)),
          Text(
              "Valid: ${offer["start"].day}-${offer["start"].month} to ${offer["end"].day}-${offer["end"].month}",
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}