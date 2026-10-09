import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'preview_screen.dart';

const _maxImages = 10;

class CakeEditScreen extends StatefulWidget {
  const CakeEditScreen({super.key, this.cake});
  final Cake? cake;
  @override
  State<CakeEditScreen> createState() => _CakeEditScreenState();
}

class _CakeEditScreenState extends State<CakeEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _desc, _ingredients, _price;
  final _picker = ImagePicker();
  Cake? _cake;
  late List<CakeImage> _images;
  final List<XFile> _pending = [];
  late bool _available, _featured;
  bool _saving = false, _dirty = false;

  ApiClient get _api => context.read<AuthState>().api;

  @override
  void initState() {
    super.initState();
    final c = widget.cake;
    _cake = c;
    _title = TextEditingController(text: c?.title ?? '');
    _desc = TextEditingController(text: c?.description ?? '');
    _ingredients = TextEditingController(text: c?.ingredients.join('\n') ?? '');
    _price = TextEditingController(text: c?.price == null ? '' : c!.price!.toStringAsFixed(c.price! == c.price!.roundToDouble() ? 0 : 2));
    _images = List.of(c?.images ?? []);
    _available = c?.isAvailable ?? true;
    _featured = c?.isFeatured ?? false;
    for (final ctl in [_title, _desc, _ingredients, _price]) {
      ctl.addListener(() => _dirty = true);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _ingredients, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _ingredientList =>
      _ingredients.text.split(RegExp(r'[\n,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  double? get _priceValue => double.tryParse(_price.text.trim().replaceAll(',', ''));

  int get _imageCount => _images.length + _pending.length;

  // ---------- photos
  Future<void> _addPhotos() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ivory,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final room = _maxImages - _imageCount;
      if (room <= 0) {
        toast(context, 'A cake can have up to $_maxImages photos', error: true);
        return;
      }
      List<XFile> picked;
      if (source == ImageSource.camera) {
        final x = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1800);
        picked = x == null ? [] : [x];
      } else {
        picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1800);
      }
      if (picked.isEmpty) return;
      setState(() {
        _pending.addAll(picked.take(room));
        _dirty = true;
      });
      if (picked.length > room) toast(context, 'Only the first $room photo(s) were added');
    } catch (_) {
      if (mounted) toast(context, 'Could not open the camera or gallery. Check app permissions.', error: true);
    }
  }

  Future<void> _deleteServerImage(CakeImage img) async {
    if (!await confirm(context, 'Remove photo?', 'This photo will be deleted permanently.', action: 'Remove')) return;
    try {
      final j = await _api.delete('/api/admin/cakes/${_cake!.id}/images/${img.id}');
      final c = Cake.fromJson(j);
      setState(() {
        _cake = c;
        _images = List.of(c.images);
      });
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _setCover(CakeImage img) async {
    try {
      final j = await _api.put('/api/admin/cakes/${_cake!.id}/images/${img.id}/cover', {});
      final c = Cake.fromJson(j);
      setState(() {
        _cake = c;
        _images = List.of(c.images);
      });
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  // ---------- save / publish
  Future<void> _save({bool publish = false}) async {
    if (!_form.currentState!.validate()) return;
    if (publish && _imageCount == 0) {
      toast(context, 'Add at least one photo before publishing', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'ingredients': _ingredientList,
        'price': _priceValue?.toStringAsFixed(2),
        'currency': 'INR',
        'is_available': _available,
        'is_featured': _featured,
      };
      Cake saved = _cake == null
          ? Cake.fromJson(await _api.post('/api/admin/cakes', body))
          : Cake.fromJson(await _api.patch('/api/admin/cakes/${_cake!.id}', body));
      _cake = saved; // remember it so a retry after a failed upload never creates a duplicate
      if (_pending.isNotEmpty) {
        saved = Cake.fromJson(await _api.upload('/api/admin/cakes/${saved.id}/images', 'files', _pending.map((x) => x.path).toList()));
        _cake = saved;
        _pending.clear();
        _images = List.of(saved.images);
      }
      if (publish) {
        saved = Cake.fromJson(await _api.post('/api/admin/cakes/${saved.id}/publish'));
        _cake = saved;
      }
      if (!mounted) return;
      toast(context, publish ? 'Published! It is live on your website.' : 'Saved');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (_cake != null) _images = List.of(_cake!.images);
        });
        toast(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _preview() async {
    final data = PreviewData(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      ingredients: _ingredientList,
      price: _priceValue,
      currency: 'INR',
      available: _available,
      images: [
        ..._images.map<ImageProvider>((i) => NetworkImage(thumb(i.url, 1000))),
        ..._pending.map<ImageProvider>((x) => FileImage(File(x.path))),
      ],
    );
    final res = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => PreviewScreen(data: data, showPublish: !(_cake?.isPublished ?? false))));
    if (res == 'publish') _save(publish: true);
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Delete this cake?', 'It will be removed from your website and cannot be recovered.')) return;
    setState(() => _saving = true);
    try {
      await _api.delete('/api/admin/cakes/${_cake!.id}');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        toast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _cake == null;
    final live = _cake?.isPublished ?? false;
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirm(context, 'Discard changes?', 'You have unsaved changes.', action: 'Discard') && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'New cake' : 'Edit cake'),
          actions: [
            if (!isNew) IconButton(tooltip: 'Delete', onPressed: _saving ? null : _delete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _saving,
          child: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
              Text('Photos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _addTile(),
                  ..._images.map(_serverTile),
                  ..._pending.map(_pendingTile),
                ]),
              ),
              if (_imageCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Add at least one photo to publish. The first (★) is the cover.', style: TextStyle(fontSize: 12.5, color: choc.withOpacity(.65))),
                ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _title,
                decoration: deco('Cake name'),
                textCapitalization: TextCapitalization.words,
                maxLength: 140,
                validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter a cake name' : null,
              ),
              const SizedBox(height: 6),
              TextFormField(controller: _desc, decoration: deco('Description', hint: 'Tell customers what makes it special'), minLines: 4, maxLines: 8, maxLength: 4000, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 10),
              TextFormField(controller: _ingredients, decoration: deco('Ingredients', hint: 'One per line (or separated by commas)'), minLines: 3, maxLines: 8, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                decoration: deco('Price (optional)', prefix: '₹ ', hint: 'Leave empty to show “Price on request”'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final n = double.tryParse(t.replaceAll(',', ''));
                  if (n == null || n < 0) return 'Enter a valid price';
                  if (n > 1000000) return 'Price is too high';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: orange, title: const Text('Available to order'), subtitle: const Text('Turn off to show “Sold out” on the website'), value: _available, onChanged: (v) => setState(() { _available = v; _dirty = true; })),
              SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: orange, title: const Text('Feature on homepage'), value: _featured, onChanged: (v) => setState(() { _featured = v; _dirty = true; })),
              const SizedBox(height: 18),
              if (live)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('This cake is live. Saving updates your website right away.', style: TextStyle(color: Colors.green.shade800, fontSize: 13)),
                ),
              OutlinedButton.icon(onPressed: _preview, icon: const Icon(Icons.visibility_outlined), label: const Text('Preview')),
              const SizedBox(height: 12),
              if (live)
                FilledButton(onPressed: () => _save(), child: _saving ? _spinner() : const Text('Save changes'))
              else ...[
                FilledButton(onPressed: () => _save(publish: true), child: _saving ? _spinner() : const Text('Save & publish')),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () => _save(), child: const Text('Save as draft')),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _spinner() => const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white));

  Widget _addTile() => GestureDetector(
        onTap: _addPhotos,
        child: Container(
          width: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(16), border: Border.all(color: orange, width: 1.5)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_a_photo_outlined, color: orange),
            SizedBox(height: 6),
            Text('Add', style: TextStyle(color: orange, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _serverTile(CakeImage img) => Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: NetImage(img.url, width: 300)),
          Positioned(
            left: 4,
            bottom: 4,
            child: _roundBtn(img.isCover ? Icons.star : Icons.star_border, () => img.isCover ? null : _setCover(img), color: img.isCover ? orange : choc),
          ),
          Positioned(right: 4, top: 4, child: _roundBtn(Icons.close, () => _deleteServerImage(img))),
        ]),
      );

  Widget _pendingTile(XFile x) => Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(x.path), fit: BoxFit.cover)),
          Positioned(left: 6, bottom: 6, child: const StatusChip('New', orange)),
          Positioned(right: 4, top: 4, child: _roundBtn(Icons.close, () => setState(() => _pending.remove(x)))),
        ]),
      );

  Widget _roundBtn(IconData icon, VoidCallback? onTap, {Color color = choc}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}
