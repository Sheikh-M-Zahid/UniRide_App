import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class AdminSafetyReportsPage extends StatefulWidget {
  const AdminSafetyReportsPage({super.key});

  @override
  State<AdminSafetyReportsPage> createState() => _AdminSafetyReportsPageState();
}

class _AdminSafetyReportsPageState extends State<AdminSafetyReportsPage> {
  final AuthApiService _api = AuthApiService();
  bool _isLoading = true;
  String _filter = 'all';
  List<dynamic> _reports = [];
  final List<String> _filters = ['all', 'pending', 'okay', 'not_okay'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getAdminSafetyReports(status: _filter);
      if (!mounted) return;
      setState(() {
        _reports = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'okay': return const Color(0xFF16A34A);
      case 'not_okay': return const Color(0xFFDC2626);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'okay': return 'I am okay';
      case 'not_okay': return 'NOT OKAY';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        title: const Text('Safety Check Reports', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) { setState(() => _filter = f); _load(); },
                  selectedColor: const Color(0xFF14B8A6),
                  labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF1F2937)),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)))
                : _reports.isEmpty
                ? const Center(child: Text('No safety-check reports found.'))
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final r = _reports[index];
                  final status = (r['status'] ?? 'pending').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: status == 'not_okay' ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
                        width: status == 'not_okay' ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r['recipient_name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_statusLabel(status),
                                  style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Phone: ${r['recipient_phone'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        Text('Ride type: ${r['ride_type'] == 'coride' ? 'CoRide' : 'Standard Ride'} (${r['recipient_role']})',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                        if (r['pickup'] != null || r['destination'] != null) ...[
                          const SizedBox(height: 4),
                          Text('${r['pickup'] ?? ''} → ${r['destination'] ?? ''}',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1F2937))),
                        ],
                        if (r['counterpart_name'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Counterpart: ${r['counterpart_name']} · ${r['counterpart_phone'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                        ],
                        if (status == 'not_okay' && (r['message'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                            child: Text(r['message'].toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D))),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}