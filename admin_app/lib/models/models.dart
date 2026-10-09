class CakeImage {
  CakeImage({required this.id, required this.url, required this.isCover});
  final String id;
  final String url;
  final bool isCover;
  factory CakeImage.fromJson(Map<String, dynamic> j) =>
      CakeImage(id: j['id'] as String, url: j['url'] as String, isCover: j['is_cover'] == true);
}

class Cake {
  Cake({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.price,
    required this.currency,
    required this.isAvailable,
    required this.isFeatured,
    required this.isPublished,
    required this.images,
  });

  final String id, slug, title, description, currency;
  final List<String> ingredients;
  final double? price;
  final bool isAvailable, isFeatured, isPublished;
  final List<CakeImage> images;

  String? get coverUrl {
    if (images.isEmpty) return null;
    return images.firstWhere((i) => i.isCover, orElse: () => images.first).url;
  }

  factory Cake.fromJson(dynamic raw) {
    final j = raw as Map<String, dynamic>;
    return Cake(
      id: j['id'] as String,
      slug: j['slug'] as String,
      title: j['title'] as String,
      description: (j['description'] ?? '') as String,
      ingredients: ((j['ingredients'] ?? []) as List).map((e) => e.toString()).toList(),
      price: j['price'] == null ? null : double.tryParse(j['price'].toString()),
      currency: (j['currency'] ?? 'INR') as String,
      isAvailable: j['is_available'] == true,
      isFeatured: j['is_featured'] == true,
      isPublished: j['is_published'] == true,
      images: ((j['images'] ?? []) as List)
          .map((e) => CakeImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

String formatPrice(double? p, String currency) {
  if (p == null) return 'Price on request';
  final symbol = {'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£'}[currency] ?? '$currency ';
  final s = p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);
  return '$symbol$s';
}

/// Cloudinary serves resized, auto-format images when asked.
String thumb(String url, [int w = 600]) {
  if (!url.contains('res.cloudinary.com') || !url.contains('/upload/')) return url;
  return url.replaceFirst('/upload/', '/upload/f_auto,q_auto,c_limit,w_$w/');
}
