import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class PreviewData {
  PreviewData({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.price,
    required this.currency,
    required this.available,
    required this.images,
  });
  final String title, description, currency;
  final List<String> ingredients;
  final double? price;
  final bool available;
  final List<ImageProvider> images;
}

/// Shows the cake roughly as customers will see it on the website.
/// Pops with 'publish' if the owner taps the publish button.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.data, this.showPublish = false});
  final PreviewData data;
  final bool showPublish;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      bottomNavigationBar: showPublish
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, 'publish'),
                  icon: const Icon(Icons.public),
                  label: const Text('Publish to website'),
                ),
              ),
            )
          : null,
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: data.images.isEmpty
                ? const CakePlaceholder()
                : PageView(children: data.images.map((p) => Image(image: p, fit: BoxFit.cover)).toList()),
          ),
        ),
        if (data.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(child: Text('Swipe for ${data.images.length} photos', style: TextStyle(color: choc.withOpacity(.6), fontSize: 12))),
          ),
        const SizedBox(height: 18),
        Text(data.available ? 'Baked to order' : 'Currently sold out', style: script(size: 28)),
        Text(data.title.isEmpty ? 'Untitled cake' : data.title, style: t.headlineSmall),
        const SizedBox(height: 6),
        Text(priceLabel(data.price, data.currency), style: t.titleLarge?.copyWith(color: orange)),
        if (data.description.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(data.description, style: const TextStyle(height: 1.6, fontSize: 15)),
        ],
        if (data.ingredients.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text("WHAT'S INSIDE", style: TextStyle(letterSpacing: 1.6, fontSize: 12, color: choc.withOpacity(.6))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.ingredients
                .map((i) => Chip(
                      label: Text(i),
                      backgroundColor: cream,
                      side: BorderSide(color: choc.withOpacity(.15)),
                      shape: const StadiumBorder(),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 26),
        const IgnorePointer(child: Opacity(opacity: .9, child: FilledButton(onPressed: null, child: Text('Enquire on WhatsApp')))),
        const SizedBox(height: 8),
        Center(child: Text('(customers will see an active WhatsApp button)', style: TextStyle(fontSize: 12, color: choc.withOpacity(.55)))),
      ]),
    );
  }
}
