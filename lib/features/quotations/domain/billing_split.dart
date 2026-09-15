class BillingSplit {
  const BillingSplit._();

  static double roundMoney(double value) {
    return double.parse(value.toStringAsFixed(3));
  }

  static List<double> splitEqually(double total, int parts) {
    if (parts < 1) {
      return const [];
    }
    if (total <= 0) {
      return List<double>.filled(parts, 0);
    }

    final slices = <double>[];
    var used = 0.0;
    for (var index = 0; index < parts; index++) {
      final isLast = index == parts - 1;
      final amount = isLast ? roundMoney(total - used) : roundMoney(total / parts);
      slices.add(amount);
      used = roundMoney(used + amount);
    }
    return slices;
  }
}
