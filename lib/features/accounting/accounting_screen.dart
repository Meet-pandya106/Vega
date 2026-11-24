import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/tax_accounting_service.dart';
import '../../core/services/csv_import_service.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  final NumberFormat _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  double _otherExpenses = 15000.0; // E.g. Trading PC, Internet, Dhan API subscriptions

  Future<void> _pickAndImportDhanCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        final content = String.fromCharCodes(result.files.single.bytes!);
        final importedTrades = CsvImportService.parseDhanTradebook(content);

        if (importedTrades.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No valid F&O trades found in the selected CSV.")),
          );
          return;
        }

        // Add to ledger
        for (final trade in importedTrades) {
          final isProfit = trade.action == 'SELL';
          final pos = PositionItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() + trade.symbol,
            symbol: trade.symbol,
            assetCategory: trade.symbol.contains('NIFTY') || trade.symbol.contains('SENSEX') ? 'INDEX_FO' : 'STOCK_FO',
            strategyName: 'Dhan CSV Import',
            tradeType: 'INTRADAY',
            status: 'CLOSED',
            isPhysicalDeliveryRisk: false,
            entryTime: DateTime.now(),
            exitTime: DateTime.now(),
            grossPnl: isProfit ? trade.tradeValue : -trade.tradeValue,
            totalCharges: trade.charges.total,
            netPnl: isProfit ? (trade.tradeValue - trade.charges.total) : (-trade.tradeValue - trade.charges.total),
            mistakeTags: [],
            setupTags: ['CSV Imported'],
            notes: 'Imported from Dhan Tradebook',
          );
          ref.read(ledgerProvider.notifier).addPosition(pos);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceVariant,
            content: Text("Successfully imported ${importedTrades.length} Dhan trades!"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import error: $e")),
      );
    }
  }

  void _showAddExpenseDialog() {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text("Add Deductible Business Expense", style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description (e.g. Trading Internet, Monitor)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Amount (₹)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dhanTeal, foregroundColor: Colors.black),
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt > 0) {
                  setState(() => _otherExpenses += amt);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final positions = ref.watch(ledgerProvider);

    final closedTradeMaps = positions.map((p) => {
      'gross_pnl': p.grossPnl,
      'total_charges': p.totalCharges,
      'is_option': true,
      'sell_turnover': p.grossPnl.abs(),
    }).toList();

    final taxSummary = TaxAccountingService.compileTaxReport(
      closedTrades: closedTradeMaps,
      totalOtherBusinessExpenses: _otherExpenses,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("F&O Taxes & Accounting"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: AppTheme.dhanTeal),
            tooltip: "Import Dhan CSV",
            onPressed: _pickAndImportDhanCsv,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ICAI TURNOVER CARD (Section 44AB Tracker)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ICAI F&O RUNNING TURNOVER",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                      ),
                      Text("FY 2026-27", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.dhanTeal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _curr.format(taxSummary.financialYearTurnover),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Calculated as |Profit| + |Loss| + Option Sell Value as per ICAI guidance for ITR-3 filing.",
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.profit.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.profit.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 14, color: AppTheme.profit),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Well within the ₹10 Crore digital turnover limit (No mandatory audit required).",
                            style: TextStyle(fontSize: 10, color: AppTheme.profit, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. NET TAXABLE BUSINESS INCOME SUMMARY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TAX COMPUTATION BREAKDOWN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 14),
                  _buildRow("Gross Trading Profit", taxSummary.grossTradingProfit),
                  _buildRow("Less: Dhan Charges & STT (Deductible)", -taxSummary.totalDhanCharges, isDeduction: true),
                  _buildRow("Less: Hardware & Internet Expenses", -taxSummary.totalOtherBusinessExpenses, isDeduction: true),
                  const SizedBox(height: 10),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Net Taxable Business Income", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      Text(
                        _curr.format(taxSummary.netTaxableBusinessIncome),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: taxSummary.netTaxableBusinessIncome >= 0 ? AppTheme.profit : AppTheme.loss,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.dhanTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long, color: AppTheme.dhanTeal, size: 18),
                    label: const Text("Add Expense", style: TextStyle(color: AppTheme.dhanTeal, fontWeight: FontWeight.w700)),
                    onPressed: _showAddExpenseDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dhanTeal,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.file_upload, size: 18),
                    label: const Text("Import Dhan CSV", style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: _pickAndImportDhanCsv,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, double amount, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(
            "${amount >= 0 && !isDeduction ? '+' : ''}${_curr.format(amount)}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDeduction ? AppTheme.warningOrange : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
