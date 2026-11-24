import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dhan_charges.dart';

class SupabaseConfig {
  static const String url = 'https://trwjzrzphhphqyqbchsa.supabase.co';
  static const String anonKey = 'sb_publishable_QJynib8WhmA1eoOvsZFcrA_ngjhzz-r';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase init fallback: $e');
    }
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

class PositionItem {
  final String id;
  final String symbol;
  final String assetCategory; // INDEX_FO or STOCK_FO
  final String strategyName;
  final String tradeType; // INTRADAY or POSITIONAL
  final String status; // OPEN or CLOSED
  final bool isPhysicalDeliveryRisk;
  final DateTime entryTime;
  final DateTime? exitTime;
  final double grossPnl;
  final double totalCharges;
  final double netPnl;
  final List<String> mistakeTags;
  final List<String> setupTags;
  final String notes;

  PositionItem({
    required this.id,
    required this.symbol,
    required this.assetCategory,
    required this.strategyName,
    required this.tradeType,
    required this.status,
    required this.isPhysicalDeliveryRisk,
    required this.entryTime,
    this.exitTime,
    required this.grossPnl,
    required this.totalCharges,
    required this.netPnl,
    required this.mistakeTags,
    required this.setupTags,
    required this.notes,
  });

  Map<String, dynamic> toSupabaseMap() {
    return {
      'symbol': symbol,
      'asset_category': assetCategory,
      'strategy_name': strategyName,
      'trade_type': tradeType,
      'status': status,
      'is_physical_delivery_risk': isPhysicalDeliveryRisk,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'gross_pnl': grossPnl,
      'total_charges': totalCharges,
      'net_pnl': netPnl,
      'mistake_tags': mistakeTags,
      'setup_tags': setupTags,
      'notes': notes,
    };
  }

  factory PositionItem.fromMap(Map<String, dynamic> map) {
    return PositionItem(
      id: map['id']?.toString() ?? '',
      symbol: map['symbol'] ?? '',
      assetCategory: map['asset_category'] ?? 'INDEX_FO',
      strategyName: map['strategy_name'] ?? 'Naked Trade',
      tradeType: map['trade_type'] ?? 'INTRADAY',
      status: map['status'] ?? 'CLOSED',
      isPhysicalDeliveryRisk: map['is_physical_delivery_risk'] ?? false,
      entryTime: DateTime.tryParse(map['entry_time']?.toString() ?? '') ?? DateTime.now(),
      exitTime: map['exit_time'] != null ? DateTime.tryParse(map['exit_time'].toString()) : null,
      grossPnl: (map['gross_pnl'] as num?)?.toDouble() ?? 0.0,
      totalCharges: (map['total_charges'] as num?)?.toDouble() ?? 0.0,
      netPnl: (map['net_pnl'] as num?)?.toDouble() ?? 0.0,
      mistakeTags: List<String>.from(map['mistake_tags'] ?? []),
      setupTags: List<String>.from(map['setup_tags'] ?? []),
      notes: map['notes'] ?? '',
    );
  }
}

class LedgerNotifier extends StateNotifier<List<PositionItem>> {
  LedgerNotifier() : super([]) {
    loadPositions();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch positions from live Supabase database
  Future<void> loadPositions() async {
    _isLoading = true;
    try {
      final client = SupabaseConfig.client;
      if (client != null) {
        final response = await client
            .from('trade_positions')
            .select('*')
            .order('entry_time', ascending: false);

        final items = (response as List)
            .map((e) => PositionItem.fromMap(e as Map<String, dynamic>))
            .toList();

        if (items.isNotEmpty) {
          state = items;
          _isLoading = false;
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading from Supabase: $e');
    }

    // Fallback to initial default data if database is empty
    if (state.isEmpty) {
      state = _initialMockPositions();
    }
    _isLoading = false;
  }

  /// Add position and persist to Supabase
  Future<void> addPosition(PositionItem pos) async {
    // Optimistic UI update
    state = [pos, ...state];

    try {
      final client = SupabaseConfig.client;
      if (client != null) {
        final inserted = await client
            .from('trade_positions')
            .insert(pos.toSupabaseMap())
            .select()
            .single();

        // Update with real database UUID
        final realId = inserted['id']?.toString() ?? pos.id;
        state = state.map((p) => p.id == pos.id ? PositionItem.fromMap(inserted) : p).toList();
      }
    } catch (e) {
      debugPrint('Supabase insert error: $e');
    }
  }

  /// Delete position from Supabase
  Future<void> removePosition(String id) async {
    state = state.where((p) => p.id != id).toList();

    try {
      final client = SupabaseConfig.client;
      if (client != null) {
        await client.from('trade_positions').delete().eq('id', id);
      }
    } catch (e) {
      debugPrint('Supabase delete error: $e');
    }
  }

  /// Close position in Supabase
  Future<void> closePosition(String id, double exitPrice, double netPnl, double charges) async {
    final exitTime = DateTime.now();

    state = state.map((p) {
      if (p.id == id) {
        return PositionItem(
          id: p.id,
          symbol: p.symbol,
          assetCategory: p.assetCategory,
          strategyName: p.strategyName,
          tradeType: p.tradeType,
          status: 'CLOSED',
          isPhysicalDeliveryRisk: false,
          entryTime: p.entryTime,
          exitTime: exitTime,
          grossPnl: p.grossPnl,
          totalCharges: charges,
          netPnl: netPnl,
          mistakeTags: p.mistakeTags,
          setupTags: p.setupTags,
          notes: p.notes,
        );
      }
      return p;
    }).toList();

    try {
      final client = SupabaseConfig.client;
      if (client != null) {
        await client.from('trade_positions').update({
          'status': 'CLOSED',
          'exit_time': exitTime.toIso8601String(),
          'total_charges': charges,
          'net_pnl': netPnl,
          'is_physical_delivery_risk': false,
        }).eq('id', id);
      }
    } catch (e) {
      debugPrint('Supabase update error: $e');
    }
  }

  static List<PositionItem> _initialMockPositions() {
    final now = DateTime.now();
    return [
      PositionItem(
        id: '1',
        symbol: 'NIFTY 24500 CE',
        assetCategory: 'INDEX_FO',
        strategyName: 'Breakout Scalp',
        tradeType: 'INTRADAY',
        status: 'CLOSED',
        isPhysicalDeliveryRisk: false,
        entryTime: now.subtract(const Duration(hours: 3)),
        exitTime: now.subtract(const Duration(hours: 2, minutes: 40)),
        grossPnl: 3450.00,
        totalCharges: 58.20,
        netPnl: 3391.80,
        mistakeTags: [],
        setupTags: ['ORB 15M', 'VWAP Support'],
        notes: 'Clean bounce off 9-EMA on 5 min chart. Exited at 1:2 R:R.',
      ),
      PositionItem(
        id: '2',
        symbol: 'BANKNIFTY 52000 PE',
        assetCategory: 'INDEX_FO',
        strategyName: 'Reversal Fade',
        tradeType: 'INTRADAY',
        status: 'CLOSED',
        isPhysicalDeliveryRisk: false,
        entryTime: now.subtract(const Duration(hours: 2)),
        exitTime: now.subtract(const Duration(hours: 1, minutes: 30)),
        grossPnl: -1200.00,
        totalCharges: 52.40,
        netPnl: -1252.40,
        mistakeTags: ['Early Entry', 'Chased Premium'],
        setupTags: ['Resistance Rejection'],
        notes: 'Entered before 5 min candle close, hit stop loss immediately.',
      ),
      PositionItem(
        id: '3',
        symbol: 'RELIANCE 3000 CE',
        assetCategory: 'STOCK_FO',
        strategyName: 'Momentum Swing',
        tradeType: 'POSITIONAL',
        status: 'OPEN',
        isPhysicalDeliveryRisk: true,
        entryTime: now.subtract(const Duration(days: 1)),
        exitTime: null,
        grossPnl: 6250.00,
        totalCharges: 64.10,
        netPnl: 6185.90,
        mistakeTags: [],
        setupTags: ['Earnings Breakout'],
        notes: 'Holding with strict SL at cost. ⚠️ Physical delivery risk warning active!',
      ),
    ];
  }
}

final ledgerProvider = StateNotifierProvider<LedgerNotifier, List<PositionItem>>((ref) {
  return LedgerNotifier();
});

final totalNetPnlProvider = Provider<double>((ref) {
  final list = ref.watch(ledgerProvider);
  return list.fold(0.0, (sum, item) => sum + item.netPnl);
});

final todayNetPnlProvider = Provider<double>((ref) {
  final list = ref.watch(ledgerProvider);
  final today = DateTime.now();
  return list
      .where((p) => p.entryTime.year == today.year && p.entryTime.month == today.month && p.entryTime.day == today.day)
      .fold(0.0, (sum, item) => sum + item.netPnl);
});
