import 'dart:math';
import '../models/dhan_charges.dart';

class DhanCalculatorService {
  /// Calculate statutory Dhan charges for a single execution (Entry or Exit)
  static DhanCharges calculateOrderCharges({
    required InstrumentType instrumentType,
    required OrderAction action,
    required double price,
    required int quantity,
    Exchange exchange = Exchange.nse,
  }) {
    if (price <= 0 || quantity <= 0) {
      return DhanCharges.zero();
    }

    final double turnover = price * quantity;

    // 1. Brokerage: Flat ₹20 for Options; ₹20 or 0.03% for Futures
    double brokerage = 0.0;
    if (instrumentType == InstrumentType.option) {
      brokerage = 20.0;
    } else {
      brokerage = min(20.0, turnover * 0.0003);
    }

    // 2. STT (Securities Transaction Tax) - Charged ONLY on SELL
    double stt = 0.0;
    if (action == OrderAction.sell) {
      if (instrumentType == InstrumentType.option) {
        // 0.1% on option premium turnover (revised Budget rule)
        stt = turnover * 0.0010;
      } else {
        // 0.02% on futures turnover
        stt = turnover * 0.0002;
      }
    }

    // 3. Exchange Turnover Charges
    double exchangeCharges = 0.0;
    if (instrumentType == InstrumentType.option) {
      // NSE Options: 0.03503% | BSE Options: 0.0325%
      final rate = (exchange == Exchange.nse) ? 0.0003503 : 0.0003250;
      exchangeCharges = turnover * rate;
    } else {
      // NSE Futures: 0.00173% | BSE Futures: 0.00175%
      final rate = (exchange == Exchange.nse) ? 0.0000173 : 0.0000175;
      exchangeCharges = turnover * rate;
    }

    // 4. Stamp Duty - Charged ONLY on BUY
    double stampDuty = 0.0;
    if (action == OrderAction.buy) {
      if (instrumentType == InstrumentType.option) {
        // 0.003% on premium turnover
        stampDuty = turnover * 0.00003;
      } else {
        // 0.002% on futures turnover
        stampDuty = turnover * 0.00002;
      }
    }

    // 5. SEBI Turnover Charges (₹10 / Crore = 0.0001%)
    final double sebiCharges = turnover * 0.000001;

    // 6. IPFT (Investor Protection Fund Trust) - NSE ~0.0001%
    final double ipftCharges = (exchange == Exchange.nse) ? (turnover * 0.000001) : 0.0;

    // 7. GST: 18% on (Brokerage + Exchange Turnover Charges + SEBI Charges)
    final double gstBase = brokerage + exchangeCharges + sebiCharges;
    final double gst = gstBase * 0.18;

    return DhanCharges(
      brokerage: _round2(brokerage),
      stt: _round2(stt),
      exchangeCharges: _round2(exchangeCharges),
      gst: _round2(gst),
      stampDuty: _round2(stampDuty),
      sebiCharges: _round2(sebiCharges),
      ipftCharges: _round2(ipftCharges),
    );
  }

  /// Complete round-trip trade analysis (Entry + Exit)
  static TradeCalculationResult evaluateRoundTrip({
    required InstrumentType instrumentType,
    required bool isLongPosition, // true: Buy first then Sell; false: Sell first (short) then Buy
    required double entryPrice,
    required double exitPrice,
    required int quantity,
    Exchange exchange = Exchange.nse,
  }) {
    final entryAction = isLongPosition ? OrderAction.buy : OrderAction.sell;
    final exitAction = isLongPosition ? OrderAction.sell : OrderAction.buy;

    final entryCharges = calculateOrderCharges(
      instrumentType: instrumentType,
      action: entryAction,
      price: entryPrice,
      quantity: quantity,
      exchange: exchange,
    );

    final exitCharges = calculateOrderCharges(
      instrumentType: instrumentType,
      action: exitAction,
      price: exitPrice,
      quantity: quantity,
      exchange: exchange,
    );

    final totalCharges = entryCharges + exitCharges;

    // P&L calculation
    final double pointsCaptured = isLongPosition ? (exitPrice - entryPrice) : (entryPrice - exitPrice);
    final double grossPnl = _round2(pointsCaptured * quantity);
    final double netPnl = _round2(grossPnl - totalCharges.total);

    final double investedCapital = entryPrice * quantity;
    final double roiPercent = (investedCapital > 0) ? _round2((netPnl / investedCapital) * 100) : 0.0;
    final double turnover = (entryPrice * quantity) + (exitPrice * quantity);

    return TradeCalculationResult(
      grossPnl: grossPnl,
      entryCharges: entryCharges,
      exitCharges: exitCharges,
      totalCharges: totalCharges,
      netPnl: netPnl,
      pointsCaptured: _round2(pointsCaptured),
      roiPercent: roiPercent,
      turnover: _round2(turnover),
    );
  }

  static double _round2(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
