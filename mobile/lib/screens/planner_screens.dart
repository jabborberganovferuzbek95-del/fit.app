import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../models.dart';
import '../ui.dart';
import 'catalog_screens.dart';
import 'session_screens.dart';

/// Mashqni sanaga mos faol rejaga qo'shadi; reja bo'lmasa o'sha hafta uchun avtomatik yaratadi.
Future<void> addExerciseToPlan(ApiClient api, Exercise ex, DateTime date, int minutes) async {
  final plans = (await api.get('/plans') as List).map((e) => Plan.fromJson(Map<String, dynamic>.from(e))).toList();
  Plan? target;
  for (final p in plans) {
    if (p.status == 'active' && p.covers(date)) {
      target = p;
      break;
    }
  }
  int planId;
  if (target != null) {
    planId = target.id;
  } else {
    final monday = mondayOf(date);
    final created = await api.post('/plans', body: {'title': "Haftalik reja", 'starts_on': isoDate(monday), 'ends_on': isoDate(monday.add(const Duration(days: 6)))});
    planId = created['id'];
  }
  await api.post('/plans/$planId/items', body: {'exercise_id': ex.id, 'planned_date': isoDate(date), 'planned_minutes': minutes});
}

class _WeekData {
  _WeekData(this.plans);
  final List<Plan> plans; // elementlari bilan
  List<PlanItem> itemsOn(DateTime d) => [for (final p in plans) for (final i in p.items) if (sameDay(i.date, d)) i];
  Plan? planOf(PlanItem item) => plans.cast<Plan?>().firstWhere((p) => p!.items.any((i) => i.id == item.id), orElse: () => null);
}

/// S10 Reja / kalendar (S11: reja yaratish va mashq qo'shish/olib tashlash shu yerda)
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _monday = mondayOf(DateTime.now());
  int _epoch = 0; // Loader'ni qayta qurish uchun

  Future<_WeekData> _load() async {
    final api = context.read<AppState>().api;
    final brief = (await api.get('/plans') as List).map((e) => Plan.fromJson(Map<String, dynamic>.from(e))).toList();
    final end = _monday.add(const Duration(days: 6));
    final overlapping = brief.where((p) => p.status == 'active' && !p.endsOn.isBefore(_monday) && !p.startsOn.isAfter(end));
    final full = await Future.wait(overlapping.map((p) async => Plan.fromJson(Map<String, dynamic>.from(await api.get('/plans/${p.id}')))));
    return _WeekData(full);
  }

  void _refresh() => setState(() => _epoch++);

  Future<void> _newPlan() async {
    final title = TextEditingController(text: "Yangi reja");
    DateTime start = _monday;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text("Yangi haftalik reja"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: "Nomi")),
            const SizedBox(height: 8),
            ListTile(contentPadding: EdgeInsets.zero, title: Text("Boshlanish: ${fmtDate(start)}"), subtitle: const Text("7 kunlik davr"), trailing: const Icon(Icons.edit_calendar), onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: start, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setS(() => start = d);
            }),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Bekor qilish")), FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(80, 40)), onPressed: () => Navigator.pop(ctx, true), child: const Text("Yaratish"))],
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    try {
      await context.read<AppState>().api.post('/plans', body: {'title': title.text.trim(), 'starts_on': isoDate(start), 'ends_on': isoDate(start.add(const Duration(days: 6)))});
      setState(() { _monday = mondayOf(start); _epoch++; });
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  Future<void> _addTo(DateTime day) async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const ModuleBadge('home'), title: const Text("Home mashqi"), onTap: () => Navigator.pop(ctx, 'home')),
        ListTile(leading: const ModuleBadge('gym'), title: const Text("Gym mashqi"), onTap: () => Navigator.pop(ctx, 'gym')),
      ])),
    );
    if (mode == null) return;
    final ex = await pickExercise(context, mode: mode);
    if (ex == null) return;
    try {
      await addExerciseToPlan(context.read<AppState>().api, ex, day, 15);
      _refresh();
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  Future<void> _removeItem(_WeekData data, PlanItem item) async {
    final plan = data.planOf(item);
    if (plan == null || !await confirm(context, "Olib tashlash", "\"${item.exercise.title}\" rejadan olib tashlansinmi?")) return;
    try {
      await context.read<AppState>().api.delete('/plans/${plan.id}/items/${item.id}');
      _refresh();
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  Future<void> _deletePlan(Plan p) async {
    if (!await confirm(context, "Rejani o'chirish", "\"${p.title}\" rejasi o'chiriladi. Bajarilgan mashg'ulotlar tarixi saqlanadi.")) return;
    try {
      await context.read<AppState>().api.delete('/plans/${p.id}');
      _refresh();
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final end = _monday.add(const Duration(days: 6));
    return Scaffold(
      appBar: AppBar(title: const Text("Haftalik reja")),
      floatingActionButton: FloatingActionButton.extended(onPressed: _newPlan, icon: const Icon(Icons.add), label: const Text("Yangi reja")),
      body: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _monday = _monday.subtract(const Duration(days: 7)))),
          Text("${fmtDate(_monday)} – ${fmtDate(end)}", style: Theme.of(context).textTheme.titleMedium),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _monday = _monday.add(const Duration(days: 7)))),
        ]),
        Expanded(
          child: Loader<_WeekData>(
            key: ValueKey('$_monday-$_epoch'),
            load: _load,
            builder: (context, data, reload) => RefreshIndicator(
              onRefresh: reload,
              child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 90), children: [
                for (final p in data.plans)
                  ListTile(dense: true, leading: const Icon(Icons.assignment_outlined), title: Text(p.title), subtitle: Text("${fmtDate(p.startsOn)} – ${fmtDate(p.endsOn)}"), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deletePlan(p))),
                if (data.plans.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text("Bu hafta uchun reja yo'q. Quyidagi kunga mashq qo'shsangiz reja avtomatik yaratiladi, yoki \"Yangi reja\" tugmasini bosing.")),
                for (var i = 0; i < 7; i++) _day(context, data, _monday.add(Duration(days: i))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _day(BuildContext context, _WeekData data, DateTime day) {
    final items = data.itemsOn(day);
    final today = sameDay(day, DateTime.now());
    return Card(
      color: today ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4) : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text("${weekdays[day.weekday - 1]}, ${two(day.day)}.${two(day.month)}${today ? ' (bugun)' : ''}", style: const TextStyle(fontWeight: FontWeight.bold))),
            IconButton(visualDensity: VisualDensity.compact, tooltip: "Mashq qo'shish", icon: const Icon(Icons.add_circle_outline), onPressed: () => _addTo(day)),
          ]),
          if (items.isEmpty) const Padding(padding: EdgeInsets.only(left: 8, bottom: 8), child: Text("Dam olish / reja yo'q", style: TextStyle(color: Colors.grey))),
          for (final it in items)
            ListTile(
              dense: true,
              leading: it.isCompleted ? const Icon(Icons.check_circle, color: Colors.green) : ModuleBadge(it.exercise.mode),
              title: Text(it.exercise.title, style: TextStyle(decoration: it.isCompleted ? TextDecoration.lineThrough : null)),
              subtitle: Text("${it.minutes} daqiqa"),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!it.isCompleted) IconButton(tooltip: "Boshlash", icon: const Icon(Icons.play_circle_fill), onPressed: () async { await startSession(context, it.exercise.mode, plan: data.planOf(it), item: it); _refresh(); }),
                IconButton(tooltip: "Olib tashlash", icon: const Icon(Icons.close), onPressed: () => _removeItem(data, it)),
              ]),
            ),
        ]),
      ),
    );
  }
}
