import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'cake_edit_screen.dart';

class CakesScreen extends StatefulWidget {
  const CakesScreen({super.key});
  @override
  State<CakesScreen> createState() => _CakesScreenState();
}

class _CakesScreenState extends State<CakesScreen> {
  List<Cake>? _cakes;
  String? _error;
  bool _loading = true;
  final _busy = <String>{};

  ApiClient get _api => context.read<AuthState>().api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final j = await _api.get('/api/admin/cakes') as List;
      if (!mounted) return;
      setState(() {
        _cakes = j.map(Cake.fromJson).toList();
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _togglePublish(Cake c, bool publish) async {
    setState(() => _busy.add(c.id));
    try {
      final j = await _api.post('/api/admin/cakes/${c.id}/${publish ? 'publish' : 'unpublish'}');
      final updated = Cake.fromJson(j);
      setState(() => _cakes = _cakes!.map((x) => x.id == c.id ? updated : x).toList());
      if (mounted) toast(context, publish ? '“${c.title}” is live on your website' : '“${c.title}” hidden from your website');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(c.id));
    }
  }

  Future<void> _open([Cake? cake]) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CakeEditScreen(cake: cake)));
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cakes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        backgroundColor: orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New cake'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : _error != null && _cakes == null
              ? ErrorRetry(_error!, () {
                  setState(() => _loading = true);
                  _load();
                })
              : RefreshIndicator(
                  color: orange,
                  onRefresh: _load,
                  child: _cakes!.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          Icon(Icons.cake_outlined, size: 64, color: choc.withOpacity(.3)),
                          const SizedBox(height: 12),
                          Center(child: Text('No cakes yet', style: Theme.of(context).textTheme.titleMedium)),
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Tap “New cake” to add your first creation.', textAlign: TextAlign.center),
                          ),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _cakes!.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (_, i) => _tile(_cakes![i]),
                        ),
                ),
    );
  }

  Widget _tile(Cake c) {
    final busy = _busy.contains(c.id);
    return Material(
      color: cream,
      borderRadius: BorderRadius.circular(20),
      elevation: 1.5,
      shadowColor: choc.withOpacity(.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(c),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 84, height: 84, child: NetImage(c.coverUrl, width: 240)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(priceLabel(c.price, c.currency), style: const TextStyle(color: orange, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [
                  c.isPublished ? const StatusChip('Live', Colors.green) : StatusChip('Draft', choc.withOpacity(.7)),
                  if (!c.isAvailable) const StatusChip('Sold out', Colors.red),
                  if (c.isFeatured) const StatusChip('Featured', orange),
                ]),
              ]),
            ),
            busy
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: orange)))
                : Switch(value: c.isPublished, activeColor: orange, onChanged: (v) => _togglePublish(c, v)),
          ]),
        ),
      ),
    );
  }
}
