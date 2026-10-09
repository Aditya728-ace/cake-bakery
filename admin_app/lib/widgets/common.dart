import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';

InputDecoration deco(String label, {String? hint, Widget? suffix, String? prefix}) => InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      prefixText: prefix,
      filled: true,
      fillColor: cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: choc.withOpacity(.15))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: choc.withOpacity(.15))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orange, width: 2)),
    );

void toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade800 : choc,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirm(BuildContext context, String title, String body, {String action = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(action, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return r == true;
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width = 600});
  final String? url;
  final BoxFit fit;
  final int width;

  @override
  Widget build(BuildContext context) {
    if (url == null) return const CakePlaceholder();
    return Image.network(
      thumb(url!, width),
      fit: fit,
      loadingBuilder: (c, child, p) => p == null ? child : Container(color: const Color(0xFFEADFCB)),
      errorBuilder: (c, e, s) => const CakePlaceholder(),
    );
  }
}

class CakePlaceholder extends StatelessWidget {
  const CakePlaceholder({super.key});
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFEBD9C2),
        alignment: Alignment.center,
        child: Icon(Icons.cake_outlined, size: 40, color: choc.withOpacity(.35)),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.color, {super.key});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry(this.message, this.onRetry, {super.key});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: orange),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, style: OutlinedButton.styleFrom(minimumSize: const Size(140, 46)), child: const Text('Try again')),
          ]),
        ),
      );
}

const _noPrice = 'Price on request';
String priceLabel(double? p, String c) => p == null ? _noPrice : formatPrice(p, c);
