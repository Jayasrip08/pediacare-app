import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class VaccineStockItem {
  final String id;
  final String name;
  final String manufacturer;
  final String batchNumber;
  final String expiryDate;
  int stockDoses;
  final int minThreshold;
  final String storageTemp;

  VaccineStockItem({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.batchNumber,
    required this.expiryDate,
    required this.stockDoses,
    required this.minThreshold,
    this.storageTemp = '2°C – 8°C',
  });

  bool get isLowStock => stockDoses <= minThreshold;
}

class VaccineInventoryScreen extends StatefulWidget {
  const VaccineInventoryScreen({super.key});

  @override
  State<VaccineInventoryScreen> createState() => _VaccineInventoryScreenState();
}

class _VaccineInventoryScreenState extends State<VaccineInventoryScreen> {
  String _selectedFilter = 'All';

  final List<VaccineStockItem> _inventory = [];

  int get _totalDoses => _inventory.fold(0, (acc, item) => acc + item.stockDoses);
  int get _lowStockCount => _inventory.where((item) => item.isLowStock).length;

  List<VaccineStockItem> get _filteredList {
    if (_selectedFilter == 'Low Stock') {
      return _inventory.where((v) => v.isLowStock).toList();
    }
    return _inventory;
  }

  void _dispenseDose(VaccineStockItem item) {
    if (item.stockDoses <= 0) return;
    setState(() => item.stockDoses -= 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Dispensed 1 dose of ${item.name}. Remaining: ${item.stockDoses} doses.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showAddBatchModal() {
    final nameCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final dosesCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    String mfg = 'Serum Institute';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Receive Vaccine Batch', style: AppText.h2),
              const SizedBox(height: 4),
              Text('Log new vials into clinic cold-chain inventory', style: AppText.muted.copyWith(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Vaccine Name',
                  hintText: 'e.g., FluQuadri Pediatric',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: batchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Batch Number',
                        hintText: 'e.g. FQ-1044',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dosesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Dose Count',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expiryCtrl,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'e.g. Nov 2027',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final count = int.tryParse(dosesCtrl.text.trim()) ?? 10;
                    setState(() {
                      _inventory.add(
                        VaccineStockItem(
                          id: 'v-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          manufacturer: mfg,
                          batchNumber: batchCtrl.text.trim().isEmpty ? 'BAT-01' : batchCtrl.text.trim(),
                          expiryDate: expiryCtrl.text.trim(),
                          stockDoses: count,
                          minThreshold: 8,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add to Stock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vaccine Stock & Cold-Chain',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppColors.primary, size: 24),
            onPressed: _showAddBatchModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cold Chain Live Sensor Widget
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinic Cold-Chain Unit #01',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              Text(
                                'WHO Cold Chain Standard (2°C – 8°C)',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '4.2°C ✅',
                            style: TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Battery: 96% • Power: Mains On', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                        Text('Last Sync: 2 mins ago', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Summary Stat Badges
              Row(
                children: [
                  Expanded(
                    child: _buildStockStat('Total Vials', '$_totalDoses', AppColors.primary, AppColors.lavender),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStockStat('Low Stock Alert', '$_lowStockCount', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStockStat('Vaccine Types', '${_inventory.length}', AppColors.mint, AppColors.mintSoft),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Low Stock'),
                ],
              ),
              const SizedBox(height: 14),

              // Vaccine List
              if (_filteredList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text('No Vaccine Batches in Stock', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap "+ Add Batch" in the top bar to record incoming vials, lot numbers, and cold-chain stock.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredList.map((item) => _buildVaccineCard(item)),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockStat(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF8FAFC),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.ink,
        fontSize: 12.5,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }

  Widget _buildVaccineCard(VaccineStockItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isLowStock ? const Color(0xFFFCA5A5) : AppColors.line.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${item.manufacturer} • Batch ${item.batchNumber}', style: AppText.muted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isLowStock ? const Color(0xFFFEE2E2) : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.isLowStock ? '${item.stockDoses} doses (Low)' : '${item.stockDoses} doses',
                  style: TextStyle(
                    color: item.isLowStock ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Exp: ${item.expiryDate}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(width: 14),
              Text('Storage: ${item.storageTemp}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.outbox_rounded, size: 15),
                label: const Text('Dispense', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                onPressed: () => _dispenseDose(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
