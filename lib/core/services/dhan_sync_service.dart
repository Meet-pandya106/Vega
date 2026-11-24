import 'package:flutter/foundation.dart';
import 'dhan_calculator_service.dart';
import 'supabase_service.dart';
import '../models/dhan_charges.dart';

/// Independent Ledger Service for Manual & Offline Entry
/// Calculates exact Dhan F&O expenses (Brokerage, STT, GST, Exchange fees)
/// and syncs directly to Supabase Cloud without requiring broker API keys.
class DhanSyncService {
  /// Commit a manual execution to Supabase with exact Dhan charge calculations
  static Future<bool> commitManualTrade({
    required String symbol,
    required InstrumentType instrumentType,
    required OrderAction action,
    required double entryPrice,
    required double exitPrice,
    required int quantity,
    required String strategyName,
    List<String> setupTags = const [],
    List<String> mistakeTags = const [],
    String notes = '',
  }) async {
    try {
      final buyPrice = action == OrderAction.buy ? entryPrice : exitPrice;
      final sellPrice = action == OrderAction.buy ? exitPrice : entryPrice;
      final points = sellPrice - buyPrice;
      final grossPnl = points * quantity;

      // Exact Dhan F&O Expense Breakdown
      final buyCharges = DhanCalculatorService.calculateOrderCharges(
        instrumentType: instrumentType,
        action: OrderAction.buy,
        price: buyPrice,
        quantity: quantity,
      );
      final sellCharges = DhanCalculatorService.calculateOrderCharges(
        instrumentType: instrumentType,
        action: OrderAction.sell,
        price: sellPrice,
        quantity: quantity,
      );
      final totalFees = buyCharges.total + sellCharges.total;
      final netPnl = grossPnl - totalFees;

      final position = PositionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: symbol,
        assetCategory: symbol.contains('NIFTY') || symbol.contains('SENSEX') ? 'INDEX_FO' : 'STOCK_FO',
        strategyName: strategyName.isNotEmpty ? strategyName : 'Manual Execution',
        tradeType: 'INTRADAY',
        status: 'CLOSED',
        isPhysicalDeliveryRisk: false,
        entryTime: DateTime.now(),
        exitTime: DateTime.now(),
        grossPnl: grossPnl,
        totalCharges: totalFees,
        netPnl: netPnl,
        mistakeTags: mistakeTags,
        setupTags: setupTags,
        notes: notes,
      );

      final client = SupabaseConfig.client;
      if (client != null) {
        await client.from('trade_positions').insert(position.toSupabaseMap());
      }
      return true;
    } catch (e) {
      debugPrint('Error committing manual trade: $e');
      return false;
    }
  }
}
