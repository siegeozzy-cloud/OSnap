import 'package:string_similarity/string_similarity.dart';

import '../core/format.dart';
import '../data/database.dart';

class ProductMatch {
  ProductMatch({this.exact, this.similar});

  /// Same name after normalising. Linked without asking.
  final Product? exact;

  /// Close but not identical. The user is asked to confirm.
  final Product? similar;
}

const _similarThreshold = 0.6;

ProductMatch matchProduct(String name, List<Product> products) {
  final norm = normalizeName(name);
  Product? best;
  var bestScore = 0.0;
  for (final p in products) {
    if (p.normalizedName == norm) return ProductMatch(exact: p);
    final score = norm.similarityTo(p.normalizedName);
    if (score > bestScore) {
      bestScore = score;
      best = p;
    }
  }
  return ProductMatch(similar: bestScore >= _similarThreshold ? best : null);
}
