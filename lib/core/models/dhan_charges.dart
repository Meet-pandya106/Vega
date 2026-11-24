enum InstrumentType {
  option,
  future,
}

enum OrderAction {
  buy,
  sell,
}

enum Exchange {
  nse,
  bse,
}

class DhanCharges {
  final double brokerage;
  final double stt;
  final double exchangeCharges;
  final double gst;
  final double stampDuty;
  final double sebiCharges;
  final double ipftCharges;

  const DhanCharges({
    required this.brokerage,
    required this.stt,
    required this.exchangeCharges,
    required this.gst,
    required this.stampDuty,
    required this.sebiCharges,
    required this.ipftCharges,
  });

  double get total =>
      brokerage +
      stt +
      exchangeCharges +
      gst +
      stampDuty +
      sebiCharges +
      ipftCharges;

  Map<String, dynamic> toMap() {
    return {
      'brokerage': brokerage,
      'stt': stt,
      'exchange_charges': exchangeCharges,
      'gst': gst,
      'stamp_duty': stampDuty,
      'sebi_charges': sebiCharges,
      'ipft_charges': ipftCharges,
      'total': total,
    };
  }

  factory DhanCharges.zero() {
    return const DhanCharges(
      brokerage: 0,
      stt: 0,
      exchangeCharges: 0,
      gst: 0,
      stampDuty: 0,
      sebiCharges: 0,
      ipftCharges: 0,
    );
  }

  DhanCharges operator +(DhanCharges other) {
    return DhanCharges(
      brokerage: brokerage + other.brokerage,
      stt: stt + other.stt,
      exchangeCharges: exchangeCharges + other.exchangeCharges,
      gst: gst + other.gst,
      stampDuty: stampDuty + other.stampDuty,
      sebiCharges: sebiCharges + other.sebiCharges,
      ipftCharges: ipftCharges + other.ipftCharges,
    );
  }
}

class TradeCalculationResult {
  final double grossPnl;
  final DhanCharges entryCharges;
  final DhanCharges exitCharges;
  final DhanCharges totalCharges;
  final double netPnl;
  final double pointsCaptured;
  final double roiPercent;
  final double turnover;

  const TradeCalculationResult({
    required this.grossPnl,
    required this.entryCharges,
    required this.exitCharges,
    required this.totalCharges,
    required this.netPnl,
    required this.pointsCaptured,
    required this.roiPercent,
    required this.turnover,
  });
}
