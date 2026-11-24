Map<String, double> getDiscountRates(List<dynamic> enabled) {
  final Map<String, double> discountRates = {};

  for (String type in enabled.cast<String>()) {
    final normalizedType = type.toLowerCase();
    double rate = 1.0;

    if (normalizedType == 'student') {
      rate = 0.7;
    } else if (normalizedType == 'senior') {
      rate = 0.5;
    } else if (normalizedType == 'child') {
      rate = 0.5;
    } else if (normalizedType == 'oku') {
      rate = 0.5;
    }

    discountRates[type] = rate;
  }

  return discountRates;
}
