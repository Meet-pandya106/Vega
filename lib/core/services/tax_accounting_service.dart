class TaxSummary {
  final double financialYearTurnover;
  final double grossTradingProfit;
  final double totalDhanCharges;
  final double totalOtherBusinessExpenses;
  final double netTaxableBusinessIncome;
  final bool requiresTaxAuditWarning;
  final int totalTradesCount;
  final int winningTradesCount;
  final int losingTradesCount;

  const TaxSummary({
    required this.financialYearTurnover,
    required this.grossTradingProfit,
    required this.totalDhanCharges,
    required this.totalOtherBusinessExpenses,
    required this.netTaxableBusinessIncome,
    required this.requiresTaxAuditWarning,
    required this.totalTradesCount,
    required this.winningTradesCount,
    required this.losingTradesCount,
  });

  double get winRate => (totalTradesCount > 0)
      ? ((winningTradesCount / totalTradesCount) * 100)
      : 0.0;
}

class TaxAccountingService {
  /// Calculate ICAI Compliant F&O Turnover
  /// Formula: Sum of absolute values of profit/loss + premium on option sale
  static double calculateTradeTurnover({
    required double grossPnl,
    required double sellPremiumTurnover,
    required bool isOption,
  }) {
    double turnover = grossPnl.abs();
    if (isOption && sellPremiumTurnover > 0) {
      turnover += sellPremiumTurnover;
    }
    return (turnover * 100).roundToDouble() / 100;
  }

  /// Compile full financial year tax summary
  static TaxSummary compileTaxReport({
    required List<Map<String, dynamic>> closedTrades,
    required double totalOtherBusinessExpenses,
  }) {
    double totalTurnover = 0.0;
    double grossTradingProfit = 0.0;
    double totalDhanCharges = 0.0;
    int winCount = 0;
    int lossCount = 0;

    for (final trade in closedTrades) {
      final gross = (trade['gross_pnl'] as num?)?.toDouble() ?? 0.0;
      final charges = (trade['total_charges'] as num?)?.toDouble() ?? 0.0;
      final isOption = trade['is_option'] == true;
      final sellTurnover = (trade['sell_turnover'] as num?)?.toDouble() ?? 0.0;

      totalTurnover += calculateTradeTurnover(
        grossPnl: gross,
        sellPremiumTurnover: sellTurnover,
        isOption: isOption,
      );

      grossTradingProfit += gross;
      totalDhanCharges += charges;

      if (gross > 0) {
        winCount++;
      } else if (gross < 0) {
        lossCount++;
      }
    }

    final netTaxable = grossTradingProfit - totalDhanCharges - totalOtherBusinessExpenses;
    // Sec 44AB digital turnover threshold: ₹10 Crore
    final bool auditWarning = totalTurnover >= 100000000.0;

    return TaxSummary(
      financialYearTurnover: (totalTurnover * 100).roundToDouble() / 100,
      grossTradingProfit: (grossTradingProfit * 100).roundToDouble() / 100,
      totalDhanCharges: (totalDhanCharges * 100).roundToDouble() / 100,
      totalOtherBusinessExpenses: (totalOtherBusinessExpenses * 100).roundToDouble() / 100,
      netTaxableBusinessIncome: (netTaxable * 100).roundToDouble() / 100,
      requiresTaxAuditWarning: auditWarning,
      totalTradesCount: closedTrades.length,
      winningTradesCount: winCount,
      losingTradesCount: lossCount,
    );
  }
}
