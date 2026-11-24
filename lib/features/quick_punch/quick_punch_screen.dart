import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/fo_master.dart';
import '../../core/models/dhan_charges.dart';
import '../../core/services/dhan_calculator_service.dart';
import '../../core/services/supabase_service.dart';

class QuickPunchScreen extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const QuickPunchScreen({super.key, required this.onSaved});

  @override
  ConsumerState<QuickPunchScreen> createState() => _QuickPunchScreenState();
}

class _QuickPunchScreenState extends ConsumerState<QuickPunchScreen> {
  String _selectedSymbol = 'NIFTY';
  bool _isStock = false;
  String _optionType = 'CE'; // CE or PE
  String _strategyType = 'SINGLE_LEG'; // SINGLE_LEG or STRADDLE
  int _strikePrice = 24500;
  int _lots = 2;
  int _lotSize = 25;
  bool _isLong = true;

  // Expiry Selection
  String _selectedExpiry = 'CURRENT_WEEK'; // CURRENT_WEEK, NEXT_WEEK, MONTHLY

  final TextEditingController _entryPriceController = TextEditingController(text: '125.00');
  final TextEditingController _exitPriceController = TextEditingController(text: '158.50');
  final TextEditingController _stopLossController = TextEditingController(text: '110.00');
  final TextEditingController _targetController = TextEditingController(text: '175.00');
  final TextEditingController _strategyController = TextEditingController(text: 'Breakout Scalp');
  final TextEditingController _notesController = TextEditingController();

  TradeCalculationResult? _calcResult;
  final NumberFormat _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final entry = double.tryParse(_entryPriceController.text) ?? 0.0;
    final exit = double.tryParse(_exitPriceController.text) ?? 0.0;
    final totalQty = _lots * _lotSize;

    if (entry > 0 && exit > 0 && totalQty > 0) {
      setState(() {
        _calcResult = DhanCalculatorService.evaluateRoundTrip(
          instrumentType: InstrumentType.option,
          isLongPosition: _isLong,
          entryPrice: entry,
          exitPrice: exit,
          quantity: totalQty,
        );
      });
    } else {
      setState(() {
        _calcResult = null;
      });
    }
  }

  void _onSymbolSelected(FoInstrument inst) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSymbol = inst.symbol;
      _isStock = !inst.isIndex;
      _lotSize = inst.lotSize;
    });
    _recalculate();
  }

  void _saveTrade() {
    if (_calcResult == null) return;
    HapticFeedback.mediumImpact();

    final newPos = PositionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: "$_selectedSymbol $_strikePrice $_optionType (${_selectedExpiry.replaceAll('_', ' ')})",
      assetCategory: _isStock ? 'STOCK_FO' : 'INDEX_FO',
      strategyName: _strategyController.text.trim().isEmpty ? 'Naked Option' : _strategyController.text.trim(),
      tradeType: 'INTRADAY',
      status: 'CLOSED',
      isPhysicalDeliveryRisk: _isStock,
      entryTime: DateTime.now().subtract(const Duration(minutes: 30)),
      exitTime: DateTime.now(),
      grossPnl: _calcResult!.grossPnl,
      totalCharges: _calcResult!.totalCharges.total,
      netPnl: _calcResult!.netPnl,
      mistakeTags: [],
      setupTags: [_strategyController.text.trim()],
      notes: _notesController.text.trim(),
    );

    // Save to Supabase & local state
    ref.read(ledgerProvider.notifier).addPosition(newPos);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceVariant,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.profit, size: 20),
            const SizedBox(width: 8),
            Text(
              "Logged: ${newPos.symbol} (Net: ${_curr.format(newPos.netPnl)})",
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = _lots * _lotSize;
    final entry = double.tryParse(_entryPriceController.text) ?? 0.0;
    final sl = double.tryParse(_stopLossController.text) ?? 0.0;
    final target = double.tryParse(_targetController.text) ?? 0.0;

    // Risk-to-Reward calculation
    final riskPerShare = (entry - sl).abs();
    final rewardPerShare = (target - entry).abs();
    final rrRatio = (riskPerShare > 0) ? (rewardPerShare / riskPerShare) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Leg Builder"),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STRATEGY MODE (SINGLE LEG vs MULTI-LEG)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _strategyType = 'SINGLE_LEG');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _strategyType == 'SINGLE_LEG' ? AppTheme.surfaceVariant : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _strategyType == 'SINGLE_LEG' ? AppTheme.dhanTeal : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Single Leg",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: _strategyType == 'SINGLE_LEG' ? AppTheme.dhanTeal : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _strategyType = 'STRADDLE');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _strategyType == 'STRADDLE' ? AppTheme.surfaceVariant : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _strategyType == 'STRADDLE' ? AppTheme.dhanTeal : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Straddle / Spread",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: _strategyType == 'STRADDLE' ? AppTheme.dhanTeal : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. UNDERLYING DERIVATIVE PILLS
            const Text(
              "UNDERLYING ASSET",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...FoMaster.indices.map((inst) {
                  final isSelected = _selectedSymbol == inst.symbol;
                  return ChoiceChip(
                    label: Text(inst.symbol),
                    selected: isSelected,
                    selectedColor: AppTheme.dhanTeal,
                    backgroundColor: AppTheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (_) => _onSymbolSelected(inst),
                  );
                }),
                ...FoMaster.topStocks.take(4).map((inst) {
                  final isSelected = _selectedSymbol == inst.symbol;
                  return ChoiceChip(
                    label: Text(inst.symbol),
                    selected: isSelected,
                    selectedColor: AppTheme.warningOrange,
                    backgroundColor: AppTheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (_) => _onSymbolSelected(inst),
                  );
                }),
              ],
            ),

            const SizedBox(height: 18),

            // 3. EXPIRY SELECTOR
            const Text(
              "CONTRACT EXPIRY",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildExpiryPill("CURRENT_WEEK", "Current Week (Thu)"),
                const SizedBox(width: 8),
                _buildExpiryPill("NEXT_WEEK", "Next Week"),
                const SizedBox(width: 8),
                _buildExpiryPill("MONTHLY", "Monthly"),
              ],
            ),

            const SizedBox(height: 18),

            // 4. CE / PE & STRIKE PRICE
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _optionType = 'CE');
                              _recalculate();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _optionType == 'CE' ? AppTheme.profit : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "CALL (CE)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _optionType == 'CE' ? Colors.black : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _optionType = 'PE');
                              _recalculate();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _optionType == 'PE' ? AppTheme.loss : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "PUT (PE)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _optionType == 'PE' ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _strikePrice.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Strike Price",
                      prefixIcon: Icon(Icons.pin, size: 16, color: AppTheme.dhanTeal),
                    ),
                    onChanged: (val) {
                      _strikePrice = int.tryParse(val) ?? _strikePrice;
                      _recalculate();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 5. LOT COUNTER & TOTAL QUANTITY
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CONTRACT LOTS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text("Total Qty: $totalQty units", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.dhanTeal)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary),
                        onPressed: _lots > 1
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() => _lots--);
                                _recalculate();
                              }
                            : null,
                      ),
                      Text("$_lots Lots", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.dhanTeal),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _lots++);
                          _recalculate();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. ENTRY & EXIT PRICE INPUTS
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _entryPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Entry Price (₹)",
                      prefixIcon: Icon(Icons.arrow_downward_rounded, size: 16, color: AppTheme.profit),
                    ),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _exitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Exit Price (₹)",
                      prefixIcon: Icon(Icons.arrow_upward_rounded, size: 16, color: AppTheme.loss),
                    ),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 7. RISK-TO-REWARD (R:R) GUARDRAIL
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "RISK / REWARD GUARDRAIL",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rrRatio >= 1.5 ? AppTheme.profitSurface : AppTheme.lossSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "R:R 1 : ${rrRatio.toStringAsFixed(1)}",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: rrRatio >= 1.5 ? AppTheme.profit : AppTheme.loss,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stopLossController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: "Stop Loss (₹)"),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _targetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: "Target (₹)"),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 8. LIVE DHAN CALCULATION CARD
            if (_calcResult != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF131A26), Color(0xFF0E121A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _calcResult!.netPnl >= 0 ? AppTheme.profit.withOpacity(0.3) : AppTheme.loss.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("REALIZED TAKE-HOME (NET P&L)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                        Text(
                          "${_calcResult!.pointsCaptured >= 0 ? '+' : ''}${_calcResult!.pointsCaptured} pts",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _calcResult!.pointsCaptured >= 0 ? AppTheme.profit : AppTheme.loss,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${_calcResult!.netPnl >= 0 ? '+' : ''}${_curr.format(_calcResult!.netPnl)}",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _calcResult!.netPnl >= 0 ? AppTheme.profit : AppTheme.loss,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.borderSubtle, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Gross P&L: ${_curr.format(_calcResult!.grossPnl)}", style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text("Dhan Fees: -${_curr.format(_calcResult!.totalCharges.total)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warningOrange)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Brokerage: ₹${_calcResult!.totalCharges.brokerage.toStringAsFixed(0)} | STT: ₹${_calcResult!.totalCharges.stt} | Exch+GST: ₹${(_calcResult!.totalCharges.exchangeCharges + _calcResult!.totalCharges.gst).toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 9. SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dhanTeal,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                label: const Text("COMMIT TO VEGA LEDGER", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                onPressed: _calcResult != null ? _saveTrade : null,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryPill(String key, String label) {
    final isSelected = _selectedExpiry == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedExpiry = key);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.dhanTeal : AppTheme.borderSubtle),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.dhanTeal : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
