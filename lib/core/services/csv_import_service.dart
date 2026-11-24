import 'package:csv/csv.dart';
import '../models/dhan_charges.dart';
import 'dhan_calculator_service.dart';

class ImportedDhanTrade {
  final String symbol;
  final String tradeDate;
  final String tradeTime;
  final String action; // BUY or SELL
  final int quantity;
  final double price;
  final double tradeValue;
  final InstrumentType instrumentType;
  final String optionType; // CE, PE, or NONE
  final double? strikePrice;
  final DhanCharges charges;

  ImportedDhanTrade({
    required this.symbol,
    required this.tradeDate,
    required this.tradeTime,
    required this.action,
    required this.quantity,
    required this.price,
    required this.tradeValue,
    required this.instrumentType,
    required this.optionType,
    this.strikePrice,
    required this.charges,
  });
}

class CsvImportService {
  /// Parses Dhan tradebook CSV string into structured trade executions
  static List<ImportedDhanTrade> parseDhanTradebook(String csvContent) {
    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: true,
    ).convert(csvContent);

    if (rows.length < 2) return [];

    // Find header index
    int headerRowIndex = -1;
    for (int i = 0; i < rows.length; i++) {
      final rowStr = rows[i].map((e) => e.toString().toLowerCase()).toList();
      if (rowStr.contains('symbol') || rowStr.contains('scrip') || rowStr.contains('trading symbol')) {
        headerRowIndex = i;
        break;
      }
    }

    if (headerRowIndex == -1) headerRowIndex = 0;

    final header = rows[headerRowIndex].map((e) => e.toString().trim().toLowerCase()).toList();
    final int symbolCol = _findColIndex(header, ['symbol', 'trading symbol', 'scrip name', 'security']);
    final int actionCol = _findColIndex(header, ['trade type', 'action', 'type', 'buy/sell']);
    final int qtyCol = _findColIndex(header, ['quantity', 'qty', 'traded qty']);
    final int priceCol = _findColIndex(header, ['price', 'avg price', 'trade price', 'rate']);
    final int dateCol = _findColIndex(header, ['trade date', 'date', 'order date']);
    final int timeCol = _findColIndex(header, ['trade time', 'time', 'order time']);

    final List<ImportedDhanTrade> result = [];

    for (int i = headerRowIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) continue;

      try {
        final symbol = (symbolCol >= 0 && symbolCol < row.length) ? row[symbolCol].toString().trim() : 'UNKNOWN';
        if (symbol.isEmpty || symbol == 'UNKNOWN') continue;

        final rawAction = (actionCol >= 0 && actionCol < row.length) ? row[actionCol].toString().trim().toUpperCase() : 'BUY';
        final isBuy = rawAction.startsWith('B');
        final actionStr = isBuy ? 'BUY' : 'SELL';

        final rawQty = (qtyCol >= 0 && qtyCol < row.length) ? row[qtyCol] : 0;
        final int quantity = (rawQty is num) ? rawQty.toInt() : int.tryParse(rawQty.toString()) ?? 0;

        final rawPrice = (priceCol >= 0 && priceCol < row.length) ? row[priceCol] : 0.0;
        final double price = (rawPrice is num) ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0.0;

        final date = (dateCol >= 0 && dateCol < row.length) ? row[dateCol].toString().trim() : '';
        final time = (timeCol >= 0 && timeCol < row.length) ? row[timeCol].toString().trim() : '';

        // Detect instrument type & strike from symbol (e.g. NIFTY 28NOV24 24500 CE)
        final upperSym = symbol.toUpperCase();
        InstrumentType instType = InstrumentType.option;
        String optType = 'NONE';
        double? strike;

        if (upperSym.endsWith('CE')) {
          instType = InstrumentType.option;
          optType = 'CE';
        } else if (upperSym.endsWith('PE')) {
          instType = InstrumentType.option;
          optType = 'PE';
        } else if (upperSym.contains('FUT')) {
          instType = InstrumentType.future;
        }

        // Try to parse strike price (digits before CE/PE)
        final strikeMatch = RegExp(r'(\d+)\s*(CE|PE)').firstMatch(upperSym);
        if (strikeMatch != null) {
          strike = double.tryParse(strikeMatch.group(1)!);
        }

        final charges = DhanCalculatorService.calculateOrderCharges(
          instrumentType: instType,
          action: isBuy ? OrderAction.buy : OrderAction.sell,
          price: price,
          quantity: quantity,
        );

        result.add(ImportedDhanTrade(
          symbol: symbol,
          tradeDate: date,
          tradeTime: time,
          action: actionStr,
          quantity: quantity,
          price: price,
          tradeValue: price * quantity,
          instrumentType: instType,
          optionType: optType,
          strikePrice: strike,
          charges: charges,
        ));
      } catch (_) {
        // Skip malformed rows
        continue;
      }
    }

    return result;
  }

  static int _findColIndex(List<String> header, List<String> candidates) {
    for (int i = 0; i < header.length; i++) {
      for (final c in candidates) {
        if (header[i].contains(c)) return i;
      }
    }
    return -1;
  }
}
