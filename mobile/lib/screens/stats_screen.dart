import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../ui.dart';
import 'results_screens.dart';

/// Statistika: Umumiy (qadam, kaloriya, faol vaqt, suv, uyqu) + Progress + Tarix
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(title: const Text("Statistika"), bottom: const TabBar(tabs: [Tab(text: "Umumiy"), Tab(text: "Progress"), Tab(text: "Tarix")])),
          body: const TabBarView(children: [StatsOverview(), ProgressView(), HistoryView()]),
        ),
      );
}

double _avgNonZero(List<int> v) {
  final nz = v.where((x) => x > 0).toList();
  return nz.isEmpty ? 0 : nz.reduce((a, b) => a + b) / nz.length;
}

class StatsOverview extends StatefulWidget {
  const StatsOverview({super.key});
  @override
  State<StatsOverview> createState() => _StatsOverviewState();
}

class _StatsOverviewState extends State<StatsOverview> {
  int _days = 7;

  Widget _card(String title, String big, String sub, List<double> series, Color color) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(big, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            MiniBars(values: series, color: color, height: 46, semanticsLabel: '$title: $big ($sub)'),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            ChoiceChip(label: const Text("Hafta"), selected: _days == 7, onSelected: (_) => setState(() => _days = 7)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text("Oy"), selected: _days == 30, onSelected: (_) => setState(() => _days = 30)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text("Yil"), selected: _days == 365, onSelected: (_) => setState(() => _days = 365)),
          ]),
        ),
        Expanded(
          child: Loader<Map<String, dynamic>>(
            key: ValueKey(_days),
            load: () => context.read<AppState>().api.getMap('/stats', query: {'days': _days}),
            builder: (context, d, reload) {
              final rows = (d['days'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
              List<double> s(String k) {
                if (_days != 365) return [for (final r in rows) (r[k] as int).toDouble()];
                final buckets = <String, List<int>>{};
                for (final r in rows) {
                  buckets.putIfAbsent((r['date'] as String).substring(0, 7), () => []).add(r[k] as int);
                }
                return [for (final v in buckets.values) k == 'sleep_min' ? _avgNonZero(v) : v.fold<int>(0, (a, b) => a + b).toDouble()];
              }
              final t = Map<String, dynamic>.from(d['totals']), a = Map<String, dynamic>.from(d['averages']);
              final sleepAvg = a['sleep_min'] as int?;
              const per = "kuniga";
              return RefreshIndicator(
                onRefresh: reload,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _card("Qadamlar", fmtInt(t['steps'] as int), "o'rtacha ${fmtInt(a['steps'] as int)} $per", s('steps'), kGreen),
                    const SizedBox(width: 12),
                    _card("Ovqat kaloriyasi", '${fmtInt(t['calories_in'] as int)} kkal', "o'rtacha ${fmtInt(a['calories_in'] as int)} $per", s('calories_in'), Colors.orange),
                  ]),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _card("Faol vaqt", fmtMinutes(t['active_minutes'] as int), "o'rtacha ${a['active_minutes']} daq $per", s('active_minutes'), Colors.purple),
                    const SizedBox(width: 12),
                    _card("Suv", '${fmtL(t['water_ml'] as int)} L', "o'rtacha ${fmtL(a['water_ml'] as int)} L $per", s('water_ml'), Colors.lightBlue),
                  ]),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _card("Uyqu", sleepAvg == null ? "N/A" : fmtSleep(sleepAvg), sleepAvg == null ? "qayd yo'q" : "o'rtacha", s('sleep_min'), Colors.indigo),
                    const SizedBox(width: 12),
                    _card("Meditatsiya", fmtMinutes(t['meditation_min'] as int), "jami", s('meditation_min'), Colors.teal),
                  ]),
                  const Text("Ko'rsatkichlar faqat siz kiritgan ma'lumotlardan hisoblanadi. Yoqilgan kaloriya hisoblanmaydi va bu tibbiy xulosa emas.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              );
            },
          ),
        ),
      ]);
}
