import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dhan_calculator_service.dart';
import 'supabase_service.dart';
import '../models/dhan_charges.dart';

class DhanSyncService {
  static const String baseUrl = 'https://api.dhan.co/v2';

  // Configured from your DhanHQ API credentials
  static const String apiKey = '5ed5ffea';
  static const String apiSecret = 'fbf30976-489f-4c7c-bf59-cb89da11007b';

  /// Fetch today's executed trades directly from Dhan servers
  static Future<List<PositionItem>> fetchTodayDhanTrades({required String clientId}) async {
    try {
      final url = Uri.parse('$baseUrl/trades');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'client-id': clientId,
          'access-token': apiSecret, // Dhan accepts Bearer token / secret
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<PositionItem> positions = [];

        for (final item in data) {
          final symbol = item['tradingSymbol'] ?? item['customSymbol'] ?? 'NIFTY';
          final action = (item['transactionType'] ?? 'BUY').toString().toUpperCase();
          final int qty = (item['tradedQuantity'] as num?)?.toInt() ?? 0;
          final double price = (item['tradedPrice'] as num?)?.toDouble() ?? 0.0;
          final isBuy = action == 'BUY';

          final isOption = symbol.contains('CE') || symbol.contains('PE');
          final isStock = !symbol.contains('NIFTY') && !symbol.contains('SENSEX');

          final charges = DhanCalculatorService.calculateOrderCharges(
            instrumentType: isOption ? InstrumentType.option : InstrumentType.future,
            action: isBuy ? OrderAction.buy : OrderAction.sell,
            price: price,
            quantity: qty,
          );

          positions.add(PositionItem(
            id: item['orderId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            symbol: symbol,
            assetCategory: isStock ? 'STOCK_FO' : 'INDEX_FO',
            strategyName: 'Dhan Auto-Sync',
            tradeType: 'INTRADAY',
            status: 'CLOSED',
            isPhysicalDeliveryRisk: isStock && isOption,
            entryTime: DateTime.tryParse(item['exchangeTime'] ?? '') ?? DateTime.now(),
            exitTime: DateTime.now(),
            grossPnl: isBuy ? -(price * qty) : (price * qty),
            totalCharges: charges.total,
            netPnl: isBuy ? -(price * qty) - charges.total : (price * qty) - charges.total,
            mistakeTags: [],
            setupTags: ['DhanHQ Sync'],
            notes: 'Synced directly from Dhan servers via DhanHQ API',
          ));
        }

        return positions;
      } else {
        debugPrint('Dhan API response error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Dhan sync exception: $e');
      return [];
    }
  }

  /// Sync Dhan trades into Supabase database automatically
  static Future<int> syncToSupabase({required String clientId}) async {
    final trades = await fetchTodayDhanTrades(clientId: clientId);
    if (trades.isEmpty) return 0;

    final client = SupabaseConfig.client;
    if (client == null) return 0;

    int syncedCount = 0;
    for (final pos in trades) {
      try {
        await client.from('trade_positions').insert(pos.toSupabaseMap());
        syncedCount++;
      } catch (e) {
        debugPrint('Supabase trade insert error: $e');
      }
    }
    return syncedCount;
  }
}
