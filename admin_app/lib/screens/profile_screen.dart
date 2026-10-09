import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

const _socials = ['instagram', 'facebook', 'youtube', 'pinterest', 'tiktok', 'x'];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _c = {
    for (final k in ['name', 'tagline', 'email', 'phone', 'whatsapp_number', 'address', ..._socials]) k: TextEditingController()
  };
  String? _logo, _error;
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

  void _fill(Map<String, dynamic> j) {
    for (final k in ['name', 'tagline', 'email', 'phone', 'whatsapp_number', 'address']) {
      _c[k]!.text = (j[k] ?? '') as String;
    }
    final links = (j['social_links'] ?? {}) as Map;
    for (final k in _socials) {
      _c[k]!.text = (links[k] ?? '').toString();
    }
    _logo = j['logo_url'] as String?;
  }

  Future<void> _load() async {
    try {
      _fill(await _api.get('/api/admin/profile') as Map<String, dynamic>);
      if (mounted) setState(() { _loading = false; _error = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    }
  }

  String? _nullIfEmpty(String k) {
    final t = _c[k]!.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final links = {for (final k in _socials) if (_c[k]!.text.trim().isNotEmpty) k: _c[k]!.text.trim()};
      final j = await _api.put('/api/admin/profile', {
        'name': _c['name']!.text.trim(),
        'tagline': _nullIfEmpty('tagline'),
        'email': _nullIfEmpty('email'),
        'phone': _nullIfEmpty('phone'),
        'whatsapp_number': _nullIfEmpty('whatsapp_number'),
        'address': _nullIfEmpty('address'),
        'social_links': links,
      });
      _fill(j as Map<String, dynamic>);
      if (mounted) toast(context, 'Bakery details saved');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLogo() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1000);
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final j = await _api.upload('/api/admin/profile/logo', 'file', [x.path]);
      setState(() => _logo = (j as Map<String, dynamic>)['logo_url'] as String?);
      if (mounted) toast(context, 'Logo updated');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    if (await confirm(context, 'Sign out?', 'You will need to sign in again.', action: 'Sign out')) {
      await context.read<AuthState>().logout();
    }
  }

  Widget _field(String k, String label, {TextInputType? type, String? hint, String? Function(String?)? validator, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(controller: _c[k], decoration: deco(label, hint: hint), keyboardType: type, validator: validator, maxLines: lines, minLines: 1),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bakery'), actions: [
        IconButton(tooltip: 'Sign out', onPressed: _logout, icon: const Icon(Icons.logout)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : _error != null
              ? ErrorRetry(_error!, () { setState(() => _loading = true); _load(); })
              : Form(
                  key: _form,
                  child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
                    Center(
                      child: GestureDetector(
                        onTap: _uploading ? null : _pickLogo,
                        child: Stack(alignment: Alignment.bottomRight, children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: const Color(0xFFEBD9C2),
                            backgroundImage: _logo == null ? null : NetworkImage(_logo!),
                            child: _uploading
                                ? const CircularProgressIndicator(color: orange)
                                : (_logo == null ? const Icon(Icons.storefront, size: 38, color: choc) : null),
                          ),
                          const CircleAvatar(radius: 17, backgroundColor: orange, child: Icon(Icons.edit, size: 16, color: Colors.white)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _field('name', 'Bakery name', validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your bakery name' : null),
                    _field('tagline', 'Tagline', hint: 'e.g. Royal cakes, baked with love'),
                    Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _field('email', 'Public email', type: TextInputType.emailAddress, validator: (v) {
                      final t = (v ?? '').trim();
                      return t.isEmpty || (t.contains('@') && t.contains('.')) ? null : 'Enter a valid email';
                    }),
                    _field('phone', 'Phone', type: TextInputType.phone),
                    _field('whatsapp_number', 'WhatsApp number', type: TextInputType.phone, hint: 'With country code, e.g. 919876543210', validator: (v) {
                      final t = (v ?? '').replaceAll(RegExp(r'[\s+\-()]'), '');
                      if (t.isEmpty) return null;
                      return RegExp(r'^\d{8,15}$').hasMatch(t) ? null : 'Digits only, with country code';
                    }),
                    _field('address', 'Address', lines: 3),
                    const SizedBox(height: 4),
                    Text('Social links', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    for (final k in _socials)
                      _field(k, '${k[0].toUpperCase()}${k.substring(1)} URL', type: TextInputType.url, hint: 'https://…', validator: (v) {
                        final t = (v ?? '').trim();
                        return t.isEmpty || t.startsWith('http://') || t.startsWith('https://') ? null : 'Must start with https://';
                      }),
                    const SizedBox(height: 10),
                    FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Save bakery details')),
                  ]),
                ),
    );
  }
}
