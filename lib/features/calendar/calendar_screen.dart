import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final NumberFormat _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final allPositions = ref.watch(ledgerProvider);

    // Group positions by Day
    final Map<DateTime, List<PositionItem>> dayTrades = {};
    for (final pos in allPositions) {
      final dateKey = DateTime(pos.entryTime.year, pos.entryTime.month, pos.entryTime.day);
      dayTrades.putIfAbsent(dateKey, () => []).add(pos);
    }

    final selectedKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final selectedDayPositions = dayTrades[selectedKey] ?? [];
    final double selectedDayNetPnl = selectedDayPositions.fold(0.0, (sum, p) => sum + p.netPnl);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trading Journal & Calendar"),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                currentDay: DateTime.now(),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  weekendTextStyle: const TextStyle(color: AppTheme.textSecondary),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.dhanTeal.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.dhanTeal),
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.dhanTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final key = DateTime(date.year, date.month, date.day);
                    final trades = dayTrades[key];
                    if (trades == null || trades.isEmpty) return null;

                    final net = trades.fold(0.0, (sum, p) => sum + p.netPnl);
                    final isGreen = net >= 0;

                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isGreen ? AppTheme.profit : AppTheme.loss,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Selected Day Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${selectedDayPositions.length} Executions Logged",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Text(
                    "${selectedDayNetPnl >= 0 ? '+' : ''}${_curr.format(selectedDayNetPnl)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: selectedDayNetPnl >= 0 ? AppTheme.profit : AppTheme.loss,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Trades on Selected Day
            if (selectedDayPositions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text("No trades recorded on this date", style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedDayPositions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pos = selectedDayPositions[index];
                  final isProfit = pos.netPnl >= 0;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pos.symbol, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                            Text(
                              "${isProfit ? '+' : ''}${_curr.format(pos.netPnl)}",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isProfit ? AppTheme.profit : AppTheme.loss),
                            ),
                          ],
                        ),
                        if (pos.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text("Note: ${pos.notes}", style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                        if (pos.mistakeTags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: pos.mistakeTags.map((m) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.loss.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(m, style: const TextStyle(fontSize: 10, color: AppTheme.loss, fontWeight: FontWeight.w700)),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
