class FoInstrument {
  final String symbol;
  final String displayName;
  final int lotSize;
  final bool isIndex;
  final double defaultStrikeStep;

  const FoInstrument({
    required this.symbol,
    required this.displayName,
    required this.lotSize,
    required this.isIndex,
    required this.defaultStrikeStep,
  });
}

class FoMaster {
  // Major Indian Indices
  static const List<FoInstrument> indices = [
    FoInstrument(symbol: 'NIFTY', displayName: 'Nifty 50', lotSize: 25, isIndex: true, defaultStrikeStep: 50.0),
    FoInstrument(symbol: 'BANKNIFTY', displayName: 'Bank Nifty', lotSize: 15, isIndex: true, defaultStrikeStep: 100.0),
    FoInstrument(symbol: 'FINNIFTY', displayName: 'Fin Nifty', lotSize: 25, isIndex: true, defaultStrikeStep: 50.0),
    FoInstrument(symbol: 'MIDCPNIFTY', displayName: 'Midcap Nifty', lotSize: 50, isIndex: true, defaultStrikeStep: 25.0),
    FoInstrument(symbol: 'SENSEX', displayName: 'BSE Sensex', lotSize: 10, isIndex: true, defaultStrikeStep: 100.0),
    FoInstrument(symbol: 'BANKEX', displayName: 'BSE Bankex', lotSize: 15, isIndex: true, defaultStrikeStep: 100.0),
  ];

  // Most Actively Traded Indian Stock Options (F&O Master with current lot sizes)
  static const List<FoInstrument> topStocks = [
    FoInstrument(symbol: 'RELIANCE', displayName: 'Reliance Industries', lotSize: 250, isIndex: false, defaultStrikeStep: 20.0),
    FoInstrument(symbol: 'HDFCBANK', displayName: 'HDFC Bank Ltd', lotSize: 550, isIndex: false, defaultStrikeStep: 10.0),
    FoInstrument(symbol: 'ICICIBANK', displayName: 'ICICI Bank Ltd', lotSize: 700, isIndex: false, defaultStrikeStep: 10.0),
    FoInstrument(symbol: 'INFY', displayName: 'Infosys Ltd', lotSize: 400, isIndex: false, defaultStrikeStep: 20.0),
    FoInstrument(symbol: 'TATAMOTORS', displayName: 'Tata Motors Ltd', lotSize: 1425, isIndex: false, defaultStrikeStep: 10.0),
    FoInstrument(symbol: 'TCS', displayName: 'Tata Consultancy Services', lotSize: 175, isIndex: false, defaultStrikeStep: 20.0),
    FoInstrument(symbol: 'SBIN', displayName: 'State Bank of India', lotSize: 1500, isIndex: false, defaultStrikeStep: 5.0),
    FoInstrument(symbol: 'BAJFINANCE', displayName: 'Bajaj Finance Ltd', lotSize: 125, isIndex: false, defaultStrikeStep: 50.0),
    FoInstrument(symbol: 'BHARTIARTL', displayName: 'Bharti Airtel Ltd', lotSize: 950, isIndex: false, defaultStrikeStep: 10.0),
    FoInstrument(symbol: 'LT', displayName: 'Larsen & Toubro Ltd', lotSize: 175, isIndex: false, defaultStrikeStep: 20.0),
    FoInstrument(symbol: 'AXISBANK', displayName: 'Axis Bank Ltd', lotSize: 625, isIndex: false, defaultStrikeStep: 10.0),
    FoInstrument(symbol: 'KOTAKBANK', displayName: 'Kotak Mahindra Bank', lotSize: 400, isIndex: false, defaultStrikeStep: 10.0),
    FoInstrument(symbol: 'MARUTI', displayName: 'Maruti Suzuki India', lotSize: 50, isIndex: false, defaultStrikeStep: 50.0),
    FoInstrument(symbol: 'ITC', displayName: 'ITC Ltd', lotSize: 1600, isIndex: false, defaultStrikeStep: 5.0),
    FoInstrument(symbol: 'TATASTEEL', displayName: 'Tata Steel Ltd', lotSize: 5500, isIndex: false, defaultStrikeStep: 1.0),
  ];

  static List<FoInstrument> search(String query) {
    final clean = query.trim().toUpperCase();
    if (clean.isEmpty) return indices;
    
    final all = [...indices, ...topStocks];
    return all.where((item) => 
      item.symbol.contains(clean) || 
      item.displayName.toUpperCase().contains(clean)
    ).toList();
  }

  static FoInstrument? getBySymbol(String symbol) {
    final clean = symbol.trim().toUpperCase();
    final all = [...indices, ...topStocks];
    try {
      return all.firstWhere((item) => item.symbol == clean);
    } catch (_) {
      return null;
    }
  }
}
