class DealInfoModel {
  final double aumEstimate;
  final List<String> products;
  final String? expectedCloseMonth;
  final int probability; // 0–100
  final String? competitorNotes;

  DealInfoModel({
    required this.aumEstimate,
    this.products = const [],
    this.expectedCloseMonth,
    this.probability = 50,
    this.competitorNotes,
  });

  String get aumDisplay {
    if (aumEstimate >= 10000000) {
      return '₹${(aumEstimate / 10000000).toStringAsFixed(1)} Cr';
    }
    if (aumEstimate >= 100000) {
      return '₹${(aumEstimate / 100000).toStringAsFixed(1)} L';
    }
    return '₹${aumEstimate.toStringAsFixed(0)}';
  }

  String get productsDisplay => products.join(', ');
}
