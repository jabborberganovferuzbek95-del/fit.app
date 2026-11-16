import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../models.dart';
import '../ui.dart';

class _ActiveData {
  _ActiveData(this.types, this.recent);
  final List<ActivityType> types;
  final List<Activity> recent;
}

/// S14 Active faollik qo'shish (qo'lda kiritish; GPS/qadam avtomatik olinmaydi — FR-12)
class ActiveScreen extends StatefulWidget {
  const ActiveScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<ActiveScreen> createState() => _ActiveScreenState();
}

class _ActiveScreenState extends State<ActiveScreen> {
  int _epoch = 0;
  int? _typeId;
  final _minutes = TextEditingController(), _km = TextEditingController(), _note = TextEditingController();
  DateTime _day = dateOnly(DateTime.now());
  String _key = newKey();
  bool _busy = false;
  String? _error;

  Future<_ActiveData> _load() async {
    final api = context.read<AppState>().api;
    final r = await Future.wait([api.get('/activity-types'), api.get('/activities', query: {'limit': 20})]);
    return _ActiveData(
      (r[0] as List).map((e) => ActivityType.fromJson(Map<String, dynamic>.from(e))).toList(),
      (r[1] as List).map((e) => Activity.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }

  Future<void> _save(List<ActivityType> types) async {
    final mins = int.tryParse(_minutes.text.trim());
    final km = _km.text.trim().isEmpty ? null : double.tryParse(_km.text.replaceAll(',', '.'));
    if (_typeId == null) return setState(() => _error = "Faollik turini tanlang");
    if (mins == null || mins < 1 || mins > 1440) return setState(() => _error = "Davomiylik 1–1440 daqiqa oralig'ida bo'lsin");
    if (_km.text.trim().isNotEmpty && (km == null || km < 0)) return setState(() => _error = "Masofa manfiy bo'lmasin");
    final now = DateTime.now();
    final when = sameDay(_day, now) ? now : DateTime(_day.year, _day.month, _day.day, 12);
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<AppState>().api.post('/activities',
          headers: {'Idempotency-Key': _key},
          body: {'activity_type_id': _typeId, 'duration_minutes': mins, 'distance_km': km, 'note': _note.text.trim().isEmpty ? null : _note.text.trim(), 'occurred_at': when.toUtc().toIso8601String()});
      _minutes.clear(); _km.clear(); _note.clear();
      _key = newKey();
      toast(context, "Faollik saqlandi");
      setState(() { _epoch++; _busy = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _delete(Activity a) async {
    if (!await confirm(context, "O'chirish", "Bu faollik qaydi o'chirilsinmi?")) return;
    try {
      await context.read<AppState>().api.delete('/activities/${a.id}');
      setState(() => _epoch++);
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.embedded ? null : AppBar(title: const Text("Active faollik")),
        body: Loader<_ActiveData>(
          key: ValueKey(_epoch),
          load: _load,
          builder: (context, d, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text("Faollik qo'shish", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(value: _typeId, decoration: const InputDecoration(labelText: "Faollik turi"), items: [for (final t in d.types) DropdownMenuItem(value: t.id, child: Text(t.title))], onChanged: (v) => setState(() => _typeId = v)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: _minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Davomiyligi, daqiqa"))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _km, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Masofa, km (ixtiyoriy)"))),
                    ]),
                    const SizedBox(height: 10),
                    TextField(controller: _note, maxLength: 500, decoration: const InputDecoration(labelText: "Izoh (ixtiyoriy)")),
                    Wrap(spacing: 8, children: [
                      ChoiceChip(label: const Text("Bugun"), selected: sameDay(_day, DateTime.now()), onSelected: (_) => setState(() => _day = dateOnly(DateTime.now()))),
                      ChoiceChip(label: const Text("Kecha"), selected: sameDay(_day, DateTime.now().subtract(const Duration(days: 1))), onSelected: (_) => setState(() => _day = dateOnly(DateTime.now().subtract(const Duration(days: 1))))),
                      ActionChip(avatar: const Icon(Icons.event, size: 18), label: Text(fmtDate(_day)), onPressed: () async {
                        final x = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
                        if (x != null) setState(() => _day = x);
                      }),
                    ]),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _busy ? null : () => _save(d.types), child: const Text("Saqlash")),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text("So'nggi faolliklar", style: Theme.of(context).textTheme.titleMedium),
              if (d.recent.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text("Hali faollik kiritilmagan"))),
              for (final a in d.recent)
                ListTile(
                  leading: const ModuleBadge('active'),
                  title: Text("${a.type.title} · ${a.minutes} daq${a.distanceKm != null ? ' · ${a.distanceKm} km' : ''}"),
                  subtitle: Text("${fmtDate(a.occurredAt)} ${fmtTime(a.occurredAt)}${a.note != null ? '\n${a.note}' : ''}"),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(a)),
                ),
            ]),
          ),
        ),
      );
}
