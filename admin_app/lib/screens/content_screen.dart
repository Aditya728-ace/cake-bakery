import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// (key, label, hint, lines)
const _fields = [
  ('announcement', 'Announcement bar', 'Shown at the very top of every page. Leave empty to hide.', 1),
  ('hero_title', 'Homepage headline', 'Cakes crafted like little celebrations', 2),
  ('hero_subtitle', 'Homepage sub-headline', 'One or two friendly sentences', 3),
  ('hero_cta_label', 'Main button text', 'Explore our cakes', 1),
  ('about_title', 'Story title', 'A little story, a lot of butter', 1),
  ('about_body', 'Your story', 'Leave a blank line between paragraphs', 8),
  ('footer_note', 'Footer note', 'Baked fresh. Made with love.', 2),
];

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});
  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final _c = {for (final f in _fields) f.$1: TextEditingController()};
  String? _hero, _error;
  bool _loading = true, _saving = false, _uploading = false;

  ApiClient get _api => context.read<AuthState>().api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final j = await _api.get('/api/admin/content') as Map<String, dynamic>;
      for (final f in _fields) {
        _c[f.$1]!.text = (j[f.$1] ?? '') as String;
      }
      final h = (j['hero_image_url'] ?? '') as String;
      if (mounted) setState(() { _hero = h.isEmpty ? null : h; _loading = false; _error = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.put('/api/admin/content', {'values': {for (final f in _fields) f.$1: _c[f.$1]!.text.trim()}});
      if (mounted) toast(context, 'Website updated. Changes show within about 30 seconds.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickHero() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800);
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final j = await _api.upload('/api/admin/content/hero-image', 'file', [x.path]);
      setState(() => _hero = (j as Map<String, dynamic>)['hero_image_url'] as String?);
      if (mounted) toast(context, 'Homepage photo updated');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Website')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : _error != null
              ? ErrorRetry(_error!, () { setState(() => _loading = true); _load(); })
              : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
                  Text('Edit the words and photo on your website. No code needed.', style: TextStyle(color: choc.withOpacity(.7))),
                  const SizedBox(height: 18),
                  Text('Homepage photo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _uploading ? null : _pickHero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 170,
                        child: Stack(fit: StackFit.expand, children: [
                          NetImage(_hero, width: 900),
                          Container(color: Colors.black.withOpacity(.25)),
                          Center(
                            child: _uploading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.photo_library_outlined, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Change photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (final f in _fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextField(controller: _c[f.$1], decoration: deco(f.$2, hint: f.$3), minLines: 1, maxLines: f.$4, maxLength: f.$1 == 'about_body' ? 5000 : 300, textCapitalization: TextCapitalization.sentences),
                    ),
                  FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Publish changes')),
                ]),
    );
  }
}
