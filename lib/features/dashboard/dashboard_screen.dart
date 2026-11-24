import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onQuickPunchTap;

  const DashboardScreen({super.key, required this.onQuickPunchTap});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isBalanceHidden = false;
  String _selectedTimeframe = '1M';
  String? _expandedTradeId;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final positions = ref.watch(ledgerProvider);
    final todayNetPnl = ref.watch(todayNetPnlProvider);
    final totalNetPnl = ref.watch(totalNetPnlProvider);

    // Calculate dynamic equity spots for FlChart
    final List<FlSpot> spots = [];
    double running = 100000.0; // Starting capital baseline
    spots.add(FlSpot(0, running));

    final closedPositions = positions.where((p) => p.status == 'CLOSED').toList().reversed.toList();
    for (int i = 0; i < closedPositions.length; i++) {
      running += closedPositions[i].netPnl;
      spots.add(FlSpot((i + 1).toDouble(), running));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (Circular Menu + Bell + Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Icon(Icons.notes_rounded, color: AppTheme.textPrimary, size: 20),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isBalanceHidden = !_isBalanceHidden);
                        },
                        icon: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Icon(
                            _isBalanceHidden ? Icons.visibility_off_outlined : Icons.notifications_none_rounded,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.cardPurple, AppTheme.cardYellow],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cardPurple.withOpacity(0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "M",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. GREETING
              const Text(
                "Hello Meet!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                "Today: ${todayNetPnl >= 0 ? '+' : ''}${_currencyFormat.format(todayNetPnl)} Realized Net 🟢",
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),

              // 3. STACKED DUAL CARDS (Exact match to reference mockup)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Back Yellow Card (Dhan Margin)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardYellow,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cardYellow.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "DHAN MARGIN",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
                              ),
                            ],
                          ),
                          Text(
                            "•••• •••• 7216",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Front Vibrant Purple Card (Realized Net P&L / Capital)
                  Container(
                    margin: const EdgeInsets.only(top: 36),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.cardPurple,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cardPurple.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "VEGA F&O",
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                ),
                              ],
                            ),
                            Text(
                              "•••• •••• 4364",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Total Realized Net",
                          style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isBalanceHidden ? "₹ ••••••••" : _currencyFormat.format(245800.0 + totalNetPnl),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TRADER",
                                  style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Meet Pandya",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                            // Nested Add Trade Action Pill
                            GestureDetector(
                              onTap: widget.onQuickPunchTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 10),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      "Add Trade",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. PROFESSIONAL INTERACTIVE FLCHART EQUITY CURVE
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "CAPITAL TRAJECTORY",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.6),
                        ),
                        Text(
                          _currencyFormat.format(spots.last.y),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.profit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Time range filter pills
                    Row(
                      children: ['1D', '1W', '1M', '3M', 'FY', 'ALL'].map((tf) {
                        final isSel = _selectedTimeframe == tf;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTimeframe = tf);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.textPrimary : AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tf,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Interactive LineChart with touch tooltips
                    SizedBox(
                      height: 110,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => Colors.black,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    _currencyFormat.format(spot.y),
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: AppTheme.profit,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.profit.withOpacity(0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. PROP-FIRM DAILY SESSIONS BARS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "WEEKLY SESSIONS",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.6),
                  ),
                  const Text(
                    "71% Green Days",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.profit),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayBar("Mon", 36, true, "+3.4k"),
                  _buildDayBar("Tue", 22, true, "+1.2k"),
                  _buildDayBar("Wed", 16, false, "-850"),
                  _buildDayBar("Thu", 46, true, "+4.5k"),
                  _buildDayBar("Fri", 26, true, "+2.1k"),
                  _buildDayBar("Mon", 22, false, "-1.2k"),
                  _buildDayBar("Today", 54, true, "+5.4k", isToday: true),
                ],
              ),

              const SizedBox(height: 26),

              // 6. ACCORDION EXECUTIONS & CONTRACT NOTE DETAILS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Executions",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.3),
                  ),
                  const Text(
                    "Tap to expand",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Accordion list of trades
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: positions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final pos = positions[index];
                  final isProfit = pos.netPnl >= 0;
                  final isExpanded = _expandedTradeId == pos.id;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _expandedTradeId = isExpanded ? null : pos.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceVariant,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Icon(
                                        isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                        color: isProfit ? AppTheme.profit : AppTheme.loss,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pos.symbol,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          DateFormat('hh:mm a • dd MMM').format(pos.entryTime),
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${isProfit ? '+' : ''}${_currencyFormat.format(pos.netPnl)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: isProfit ? AppTheme.profit : AppTheme.loss,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.textMuted,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expandable Accordion Body showing Dhan charges
                        if (isExpanded)
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                _buildFeeRow("Gross Realized P&L:", pos.grossPnl, isProfit: pos.grossPnl >= 0),
                                const SizedBox(height: 6),
                                _buildFeeRow("Dhan Statutory Charges:", -pos.totalCharges, isDeduction: true),
                                const Divider(color: AppTheme.borderSubtle, height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Realized Net Take-Home:", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                                    Text(
                                      "${isProfit ? '+' : ''}${_currencyFormat.format(pos.netPnl)}",
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isProfit ? AppTheme.profit : AppTheme.loss),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayBar(String day, double height, bool isGreen, String label, {bool isToday = false}) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.surfaceVariant : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isToday ? AppTheme.profit.withOpacity(0.4) : AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(fontSize: 10, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600, color: isToday ? AppTheme.textPrimary : AppTheme.textMuted)),
          const SizedBox(height: 6),
          Container(
            width: 8,
            height: height,
            decoration: BoxDecoration(
              color: isGreen ? AppTheme.profit : AppTheme.loss,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: (isGreen ? AppTheme.profit : AppTheme.loss).withOpacity(0.3), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isGreen ? AppTheme.profit : AppTheme.loss)),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, double val, {bool isProfit = true, bool isDeduction = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(
          "${val >= 0 && !isDeduction ? '+' : ''}${_currencyFormat.format(val)}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDeduction ? AppTheme.loss : (isProfit ? AppTheme.profit : AppTheme.loss),
          ),
        ),
      ],
    );
  }
}
