import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../models.dart';
import '../navigation.dart';
import '../ui.dart';
import 'active_screen.dart';
import 'planner_screens.dart';
import 'programs_screens.dart';

const _diffLabels = {'beginner': "Boshlang'ich", 'intermediate': "O'rta", 'advanced': "Tajribali"};

/// S07/S08 Mashqlar katalogi: Home va Gym yorliqlari, qidiruv va filtr
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Mashqlar"),
            actions: [IconButton(tooltip: "Haftalik reja", icon: const Icon(Icons.calendar_month), onPressed: () => AppNav.pushSharedAxis(context, const PlannerScreen()))],
            bottom: const TabBar(tabs: [Tab(text: "Dasturlar"), Tab(text: "Uyda"), Tab(text: "Zalda"), Tab(text: "Faollik")]),
          ),
          body: const TabBarView(children: [ProgramsTab(), ExerciseList(mode: 'home'), ExerciseList(mode: 'gym'), ActiveScreen(embedded: true)]),
        ),
      );
}

class ExerciseList extends StatefulWidget {
  const ExerciseList({super.key, required this.mode, this.onPick});
  final String mode;
  final void Function(Exercise)? onPick; // tanlash rejimi (picker)
  @override
  State<ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList> with AutomaticKeepAliveClientMixin {
  String _q = '';
  String? _difficulty, _equipment;

  @override
  bool get wantKeepAlive => true;

  Future<List<Exercise>> _load() async {
    final j = await context.read<AppState>().api.get('/exercises', query: {'mode': widget.mode, 'limit': 200}) as List;
    return j.map((e) => Exercise.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Loader<List<Exercise>>(
      load: _load,
      builder: (context, all, reload) {
        final equipment = {for (final e in all) e.equipment}.toList()..sort();
        final list = all.where((e) => e.title.toLowerCase().contains(_q.toLowerCase()) && (_difficulty == null || e.difficulty == _difficulty) && (_equipment == null || e.equipment == _equipment)).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Mashq nomi bo'yicha qidirish", isDense: true), onChanged: (v) => setState(() => _q = v)),
          ),
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              for (final d in _diffLabels.entries)
                Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: Text(d.value), selected: _difficulty == d.key, onSelected: (s) => setState(() => _difficulty = s ? d.key : null))),
              for (final e in equipment)
                Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: Text(equipmentLabel(e)), selected: _equipment == e, onSelected: (s) => setState(() => _equipment = s ? e : null))),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: reload,
              child: list.isEmpty
                  ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text("Mos mashq topilmadi")))])
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return ListTile(
                          leading: ModuleBadge(e.mode),
                          title: Text(e.title),
                          subtitle: Text("${_diffLabels[e.difficulty]} · ${equipmentLabel(e.equipment)}${e.durationHint != null ? '\n${e.durationHint}' : ''}"),
                          isThreeLine: e.durationHint != null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onPick != null ? widget.onPick!(e) : AppNav.pushSharedAxis(context, ExerciseDetailScreen(exercise: e)),
                        );
                      },
                    ),
            ),
          ),
        ]);
      },
    );
  }
}

/// S09 Mashq tafsiloti
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});
  final Exercise exercise;

  Future<void> _addToPlan(BuildContext context) async {
    DateTime date = dateOnly(DateTime.now());
    double minutes = 10;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text("Rejaga qo'shish", style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text("${weekdays[date.weekday - 1]}, ${fmtDate(date)}"),
              trailing: const Text("O'zgartirish"),
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: date, firstDate: dateOnly(DateTime.now()), lastDate: DateTime.now().add(const Duration(days: 90)));
                if (d != null) setS(() => date = d);
              },
            ),
            Text("Davomiyligi: ${minutes.round()} daqiqa"),
            Slider(value: minutes, min: 5, max: 90, divisions: 17, onChanged: (v) => setS(() => minutes = v)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Qo'shish")),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await addExerciseToPlan(context.read<AppState>().api, exercise, date, minutes.round());
      toast(context, "Rejaga qo'shildi: ${fmtDate(date)}");
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(exercise.title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            ModuleBadge(exercise.mode),
            const SizedBox(width: 12),
            Expanded(child: Wrap(spacing: 8, children: [Chip(label: Text(modeLabels[exercise.mode]!)), Chip(label: Text(_diffLabels[exercise.difficulty]!)), Chip(label: Text(equipmentLabel(exercise.equipment)))])),
          ]),
          const SizedBox(height: 16),
          Text("Qanday bajariladi", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(exercise.description),
          if (exercise.durationHint != null) ...[
            const SizedBox(height: 12),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.timer_outlined), title: const Text("Namunaviy hajm"), subtitle: Text(exercise.durationHint!)),
          ],
          const SizedBox(height: 12),
          SafetyBanner(text: exercise.safetyNote),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () => _addToPlan(context), icon: const Icon(Icons.event_available), label: const Text("Rejaga qo'shish")),
        ]),
      );
}

/// Mashq tanlash oynasi (reja va seans uchun)
Future<Exercise?> pickExercise(BuildContext context, {required String mode}) => showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Text("Mashq tanlang (${modeLabels[mode]})", style: Theme.of(ctx).textTheme.titleLarge)),
          Expanded(child: ExerciseList(mode: mode, onPick: (e) => Navigator.pop(ctx, e))),
        ]),
      ),
    );
