import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../models.dart';
import '../navigation.dart';
import '../ui.dart';
import 'catalog_screens.dart';

/// S12: seansni boshlaydi (yoki mavjud tugallanmagan seansni davom ettiradi) va S13 ekranini ochadi.
Future<void> startSession(BuildContext context, String mode, {Plan? plan, PlanItem? item}) async {
  final api = context.read<AppState>().api;
  try {
    final open = await api.get('/sessions', query: {'status': 'in_progress', 'mode': mode, 'limit': 1}) as List;
    int id;
    if (open.isNotEmpty) {
      id = open.first['id'];
      toast(context, "Tugallanmagan ${modeLabels[mode]} seansi davom ettirildi");
    } else {
      final s = await api.post('/sessions', body: {'mode': mode, if (plan != null) 'plan_id': plan.id});
      id = s['id'];
    }
    await AppNav.pushSlideUp(context, SessionScreen(sessionId: id, focus: item));
  } on ApiException catch (e) {
    toast(context, e.message);
  }
}

class _SessionData {
  _SessionData(this.session, this.planned);
  final Session session;
  final List<PlanItem> planned;
}

/// S13 Seans davomida qayd
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.sessionId, this.focus});
  final int sessionId;
  final PlanItem? focus;
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _epoch = 0;
  DateTime? _started;

  Future<_SessionData> _load() async {
    final api = context.read<AppState>().api;
    final s = Session.fromJson(Map<String, dynamic>.from(await api.get('/sessions/${widget.sessionId}')));
    var planned = <PlanItem>[];
    if (s.planId != null) {
      final plan = Plan.fromJson(Map<String, dynamic>.from(await api.get('/plans/${s.planId}')));
      planned = plan.items.where((i) => i.exercise.mode == s.mode && !i.isCompleted && (sameDay(i.date, DateTime.now()) || i.id == widget.focus?.id)).toList();
    }
    return _SessionData(s, planned);
  }

  Future<void> _log(Session s, Exercise ex, {int? planItemId}) async {
    final nextSet = s.logs.where((l) => l.exercise.id == ex.id).length + 1;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LogSheet(session: s, exercise: ex, nextSet: nextSet, planItemId: planItemId),
    );
    if (ok == true) setState(() => _epoch++);
  }

  Future<void> _add(Session s) async {
    final ex = await pickExercise(context, mode: s.mode);
    if (ex != null) await _log(s, ex);
  }

  Future<void> _deleteLog(Session s, LogEntry l) async {
    try {
      await context.read<AppState>().api.delete('/sessions/${s.id}/logs/${l.id}');
      setState(() => _epoch++);
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final leave = await confirm(
            context,
            "Seansni to'xtatasizmi?",
            "Mashg'ulot saqlanib qoladi, keyinroq davom ettirishingiz mumkin.",
            ok: "Chiqish",
          );
          if (leave && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Material(
          child: Loader<_SessionData>(
            key: ValueKey(_epoch),
            load: _load,
            builder: (context, d, reload) {
          final s = d.session;
          _started = s.startedAt;
          final byExercise = <int, List<LogEntry>>{};
          for (final l in s.logs) {
            byExercise.putIfAbsent(l.exercise.id, () => []).add(l);
          }
          return Scaffold(
            appBar: AppBar(title: Text("${modeLabels[s.mode]} seansi"), actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Elapsed(_started!)))]),
            floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(s), icon: const Icon(Icons.add), label: const Text("Mashq qo'shish")),
            body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
              if (d.planned.isNotEmpty) ...[
                Text("Rejadagi mashqlar", style: Theme.of(context).textTheme.titleMedium),
                for (final it in d.planned)
                  Card(
                    child: ListTile(
                      leading: ModuleBadge(it.exercise.mode),
                      title: Text(it.exercise.title),
                      subtitle: Text(s.logs.any((l) => l.planItemId == it.id) ? "Qayd qilindi — yana yondashuv qo'shish mumkin" : "${it.minutes} daqiqa"),
                      trailing: FilledButton.tonal(style: FilledButton.styleFrom(minimumSize: const Size(80, 40)), onPressed: () => _log(s, it.exercise, planItemId: it.id), child: const Text("Qayd")),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              Text("Bajarilgan qaydlar", style: Theme.of(context).textTheme.titleMedium),
              if (s.logs.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text("Hali qayd yo'q. \"Mashq qo'shish\" tugmasini bosing."))),
              for (final entry in byExercise.entries)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.all(8), child: Text(entry.value.first.exercise.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      for (final l in entry.value)
                        ListTile(dense: true, leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: Text(l.summary), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteLog(s, l))),
                    ]),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.flag),
                label: const Text("Seansni yakunlash"),
                onPressed: () async {
                  final done = await AppNav.pushSlideUp<bool>(context, FinishScreen(sessionId: s.id));
                  if (done == true && mounted) Navigator.pop(context);
                },
              ),
            ]),
          );
        },
      ),
    ),
  );
}

class _LogSheet extends StatefulWidget {
  const _LogSheet({required this.session, required this.exercise, required this.nextSet, this.planItemId});
  final Session session;
  final Exercise exercise;
  final int nextSet;
  final int? planItemId;
  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  late final _set = TextEditingController(text: '${widget.nextSet}');
  final _reps = TextEditingController(), _weight = TextEditingController(), _secs = TextEditingController();
  final _key = newKey(); // takror bosishdan himoya (Idempotency-Key)
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final set = int.tryParse(_set.text);
    final reps = _reps.text.trim().isEmpty ? null : int.tryParse(_reps.text);
    final secs = _secs.text.trim().isEmpty ? null : int.tryParse(_secs.text);
    final weight = _weight.text.trim().isEmpty ? null : double.tryParse(_weight.text.replaceAll(',', '.'));
    if (set == null || set < 1) return setState(() => _error = "Yondashuv raqami 1 yoki undan katta bo'lsin");
    if (reps == null && secs == null) return setState(() => _error = "Takror yoki vaqt (soniya) kiriting");
    if ((reps != null && reps < 1) || (secs != null && secs < 1)) return setState(() => _error = "Qiymatlar 0 dan katta bo'lishi kerak");
    if (_weight.text.trim().isNotEmpty && (weight == null || weight < 0)) return setState(() => _error = "Vazn manfiy bo'lmasin");
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<AppState>().api.post('/sessions/${widget.session.id}/logs',
          headers: {'Idempotency-Key': _key},
          body: {'exercise_id': widget.exercise.id, 'set_no': set, 'reps': reps, 'duration_seconds': secs, if (weight != null) 'weight_kg': weight, if (widget.planItemId != null) 'plan_item_id': widget.planItemId});
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Widget _num(TextEditingController c, String label, {bool decimal = false}) =>
      Expanded(child: TextField(controller: c, keyboardType: TextInputType.numberWithOptions(decimal: decimal), decoration: InputDecoration(labelText: label)));

  @override
  Widget build(BuildContext context) {
    final gym = widget.session.mode == 'gym';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.exercise.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(gym ? "Yondashuv, takror va (ixtiyoriy) vazn" : "Takror yoki bajarilgan vaqt (soniya)", style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        Row(children: [_num(_set, "Yondashuv №"), const SizedBox(width: 8), _num(_reps, "Takror")]),
        const SizedBox(height: 8),
        Row(children: [if (gym) ...[_num(_weight, "Vazn, kg", decimal: true), const SizedBox(width: 8)], _num(_secs, "Vaqt, soniya")]),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _save, child: const Text("Saqlash")),
      ]),
    );
  }
}

/// S15 Seans yakuni
class FinishScreen extends StatefulWidget {
  const FinishScreen({super.key, required this.sessionId});
  final int sessionId;
  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  final _notes = TextEditingController();
  bool _busy = false;

  Future<void> _end(String status) async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().api.patch('/sessions/${widget.sessionId}', body: {'status': status, if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim()});
      if (!mounted) return;
      toast(context, status == 'completed' ? "Mashg'ulot saqlandi. Barakalla!" : "Seans to'xtatildi (progressga qo'shilmaydi)");
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) { setState(() => _busy = false); toast(context, e.message); }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Seans yakuni")),
        body: Loader<Session>(
          load: () async => Session.fromJson(Map<String, dynamic>.from(await context.read<AppState>().api.get('/sessions/${widget.sessionId}'))),
          builder: (context, s, _) {
            final exercises = {for (final l in s.logs) l.exercise.title}.length;
            final mins = DateTime.now().difference(s.startedAt).inMinutes;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [StatTile("Davomiylik", fmtMinutes(mins), icon: Icons.timer), StatTile("Mashqlar", '$exercises', icon: Icons.list_alt), StatTile("Yondashuvlar", '${s.logs.length}', icon: Icons.repeat)]),
              const SizedBox(height: 12),
              TextField(controller: _notes, maxLines: 3, maxLength: 1000, decoration: const InputDecoration(labelText: "Qaydlar (ixtiyoriy)")),
              const SizedBox(height: 12),
              if (s.logs.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 12), child: Text("Saqlash uchun kamida bitta mashq qaydi kerak. Aks holda seansni to'xtating.", style: TextStyle(color: Colors.orange))),
              FilledButton(onPressed: _busy || s.logs.isEmpty ? null : () => _end('completed'), child: const Text("Saqlash va yakunlash")),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _busy ? null : () async { if (await confirm(context, "Seansni to'xtatish", "Seans progressga qo'shilmaydi. Davom etasizmi?")) _end('interrupted'); }, child: const Text("Saqlamasdan to'xtatish")),
            ]);
          },
        ),
      );
}
