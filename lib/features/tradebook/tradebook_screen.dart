import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';

class TradebookScreen extends ConsumerStatefulWidget {
  const TradebookScreen({super.key});

  @override
  ConsumerState<TradebookScreen> createState() => _TradebookScreenState();
}

class _TradebookScreenState extends ConsumerState<TradebookScreen> {
  String _filter = 'ALL'; // ALL, INDEX_FO, STOCK_FO, OPEN
  final NumberFormat _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  void _showContractNoteModal(PositionItem pos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pos.symbol,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Execution Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(pos.entryTime)}",
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 8),
              _buildModalRow("Gross Realized P&L", pos.grossPnl, isAmount: true),
              _buildModalRow("Total Dhan Statutory Charges", -pos.totalCharges, isAmount: true, isDeduction: true),
              const SizedBox(height: 8),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 8),
              _buildModalRow("Realized Net P&L", pos.netPnl, isAmount: true, isHighlight: true),
              const SizedBox(height: 16),
              if (pos.notes.isNotEmpty) ...[
                const Text("Trader Journal Notes:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(pos.notes, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.loss,
                    side: BorderSide(color: AppTheme.loss.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(ledgerProvider.notifier).removePosition(pos.id);
                    Navigator.pop(context);
                  },
                  child: const Text("Delete Trade Entry"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String title, double value, {bool isAmount = false, bool isDeduction = false, bool isHighlight = false}) {
    Color valColor = AppTheme.textPrimary;
    if (isHighlight) {
      valColor = value >= 0 ? AppTheme.profit : AppTheme.loss;
    } else if (isDeduction) {
      valColor = AppTheme.warningOrange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isHighlight ? 14 : 13, fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500, color: AppTheme.textSecondary)),
          Text(
            isAmount ? "${value >= 0 && !isDeduction ? '+' : ''}${_curr.format(value)}" : value.toString(),
            style: TextStyle(fontSize: isHighlight ? 16 : 14, fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600, color: valColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPositions = ref.watch(ledgerProvider);
    final filtered = allPositions.where((pos) {
      if (_filter == 'INDEX_FO') return pos.assetCategory == 'INDEX_FO';
      if (_filter == 'STOCK_FO') return pos.assetCategory == 'STOCK_FO';
      if (_filter == 'OPEN') return pos.status == 'OPEN';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("F&O Tradebook"),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("ALL", "All (${allPositions.length})"),
                const SizedBox(width: 8),
                _buildFilterChip("INDEX_FO", "Index F&O"),
                const SizedBox(width: 8),
                _buildFilterChip("STOCK_FO", "Stock Options"),
                const SizedBox(width: 8),
                _buildFilterChip("OPEN", "Open Positions"),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text("No trades found in this category", style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pos = filtered[index];
                      final isProfit = pos.netPnl >= 0;

                      return InkWell(
                        onTap: () => _showContractNoteModal(pos),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        pos.symbol,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: pos.status == 'OPEN' ? AppTheme.warningOrange.withOpacity(0.15) : AppTheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          pos.status,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: pos.status == 'OPEN' ? AppTheme.warningOrange : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${isProfit ? '+' : ''}${_curr.format(pos.netPnl)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isProfit ? AppTheme.profit : AppTheme.loss,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd MMM, hh:mm a').format(pos.entryTime),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                  Text(
                                    "Charges: ₹${pos.totalCharges.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.dhanTeal,
      backgroundColor: AppTheme.surfaceVariant,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _filter = key),
    );
  }
}
