import 'package:flutter_test/flutter_test.dart';
import '../lib/core/models/dhan_charges.dart';
import '../lib/core/services/dhan_calculator_service.dart';
import '../lib/core/services/tax_accounting_service.dart';

void main() {
  group('Dhan F&O Charges Engine Tests', () {
    test('Options Round Trip Calculation (Nifty 2 Lots)', () {
      // Nifty 2 Lots = 50 Qty
      // Entry Buy at ₹120, Exit Sell at ₹150
      final result = DhanCalculatorService.evaluateRoundTrip(
        instrumentType: InstrumentType.option,
        isLongPosition: true,
        entryPrice: 120.0,
        exitPrice: 150.0,
        quantity: 50,
      );

      // Points captured: 150 - 120 = 30 pts
      expect(result.pointsCaptured, 30.0);

      // Gross P&L = 30 * 50 = ₹1,500
      expect(result.grossPnl, 1500.0);

      // Brokerage: ₹20 on Entry + ₹20 on Exit = ₹40
      expect(result.totalCharges.brokerage, 40.0);

      // STT on Option Sell: 0.1% on (150 * 50 = 7,500) = ₹7.50
      expect(result.totalCharges.stt, 7.50);

      // Net P&L should be positive and less than gross
      expect(result.netPnl, lessThan(result.grossPnl));
      expect(result.netPnl, greaterThan(1400.0));
    });

    test('ICAI Turnover Calculation', () {
      // Trade 1: +₹5,000 profit
      // Trade 2: -₹3,000 loss
      final trades = [
        {'gross_pnl': 5000.0, 'total_charges': 55.0, 'is_option': true, 'sell_turnover': 20000.0},
        {'gross_pnl': -3000.0, 'total_charges': 55.0, 'is_option': true, 'sell_turnover': 15000.0},
      ];

      final summary = TaxAccountingService.compileTaxReport(
        closedTrades: trades,
        totalOtherBusinessExpenses: 2000.0,
      );

      // Gross profit = 5000 - 3000 = 2000
      expect(summary.grossTradingProfit, 2000.0);
      expect(summary.totalDhanCharges, 110.0);
      // Net Taxable = 2000 - 110 - 2000 = -110 (Business loss)
      expect(summary.netTaxableBusinessIncome, -110.0);
    });
  });
}
