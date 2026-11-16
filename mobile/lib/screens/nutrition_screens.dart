import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../motion.dart';
import '../navigation.dart';
import '../ui.dart';

ApiClient _api(BuildContext c) => c.read<AppState>().api;

class _NutData {
  _NutData(this.recipes, this.meals, this.goal);
  final List<Map<String, dynamic>> recipes, meals;
  final int goal;
}

/// Ovqatlanish bo'limi: retseptlar + bugungi ovqat qaydi
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _epoch = 0;
  String? _type;

  Future<_NutData> _load() async {
    final api = _api(context);
    final r = await Future.wait([api.getList('/recipes', query: {'limit': 100}), api.getList('/meals'), api.getMap('/goals')]);
    return _NutData(r[0] as List<Map<String, dynamic>>, r[1] as List<Map<String, dynamic>>, (r[2] as Map<String, dynamic>)['calorie_goal'] as int);
  }

  Future<void> _delete(int id) async {
    try {
      await _api(context).delete('/meals/$id');
      setState(() => _epoch++);
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Ovqatlanish")),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text("Ovqat qo'shish"),
          onPressed: () async {
            if (await addCustomMeal(context)) setState(() => _epoch++);
          },
        ),
        body: Loader<_NutData>(
          key: ValueKey(_epoch),
          load: _load,
          builder: (context, d, reload) {
            final eaten = d.meals.fold<int>(0, (a, m) => a + (m['kcal'] as int));
            final list = d.recipes.where((r) => _type == null || r['meal_type'] == _type).toList();
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
                AppCard(
                  color: kGreen,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Bugun iste'mol qilingan", style: TextStyle(color: Colors.white70)),
                    Text('${fmtInt(eaten)} kkal', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: d.goal == 0 ? 0 : (eaten / d.goal).clamp(0.0, 1.0).toDouble(), backgroundColor: Colors.white24, color: kMint, minHeight: 8),
                    const SizedBox(height: 6),
                    Text('Maqsad: ${fmtInt(d.goal)} kkal (o\'zingiz belgilagansiz)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
                if (d.meals.isNotEmpty) ...[
                  Text("Bugungi ovqatlar", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  for (final m in d.meals)
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(children: [
                        Icon(mealIcon(m['meal_type'] as String), color: mealColor(m['meal_type'] as String)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)), Text(mealTypeLabels[m['meal_type']] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
                        Text('${m['kcal']} kkal'),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(m['id'] as int)),
                      ]),
                    ),
                  const SizedBox(height: 8),
                ],
                Text("Retseptlar", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(
                  height: 52,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    Padding(padding: const EdgeInsets.only(right: 6, top: 8), child: ChoiceChip(label: const Text("Hammasi"), selected: _type == null, onSelected: (_) => setState(() => _type = null))),
                    for (final e in mealTypeLabels.entries)
                      Padding(padding: const EdgeInsets.only(right: 6, top: 8), child: ChoiceChip(label: Text(e.value), selected: _type == e.key, onSelected: (_) => setState(() => _type = e.key))),
                  ]),
                ),
                if (list.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text("Bu toifada retsept yo'q"))),
                for (var i = 0; i < list.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: (i < 6 ? i : 5) * 55),
                    child: AppCard(
                      onTap: () async {
                        final added = await AppNav.pushSharedAxis<bool>(context, RecipeDetailScreen(recipe: list[i]));
                        if (added == true) setState(() => _epoch++);
                      },
                      child: Row(children: [
                        Hero(
                          tag: 'recipe-${list[i]['id']}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: mealColor(list[i]['meal_type'] as String).withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                              child: Icon(mealIcon(list[i]['meal_type'] as String), color: mealColor(list[i]['meal_type'] as String), size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(list[i]['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${mealTypeLabels[list[i]['meal_type']]} · ${list[i]['kcal']} kkal · ${list[i]['prep_minutes']} daqiqa', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ])),
                        const Icon(Icons.chevron_right),
                      ]),
                    ),
                  ),
                const Text("Kaloriya qiymatlari taxminiy. Ilova dietolog maslahatini almashtirmaydi; maxsus parhez yoki kasallik bo'lsa mutaxassisga murojaat qiling.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            );
          },
        ),
      );
}

/// Retsept tafsiloti + bugungi ovqatga qo'shish
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipe});
  final Map<String, dynamic> recipe;

  Future<void> _add(BuildContext context) async {
    var type = recipe['meal_type'] == 'detox' ? 'snack' : recipe['meal_type'] as String;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text("Qaysi ovqat uchun?", style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final e in mealTypeLabels.entries.where((e) => e.key != 'detox'))
                ChoiceChip(label: Text(e.value), selected: type == e.key, onSelected: (_) => setS(() => type = e.key)),
            ]),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(ctx, type), child: const Text("Qo'shish")),
          ]),
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await _api(context).post('/meals', body: {'recipe_id': recipe['id'], 'meal_type': chosen});
      toast(context, "Bugungi ovqatga qo'shildi");
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = recipe['meal_type'] as String;
    final ingredients = (recipe['ingredients'] as String).split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(recipe['title'] as String)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Hero(
          tag: 'recipe-${recipe['id']}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              height: 140,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [mealColor(t).withOpacity(0.7), mealColor(t)])),
              child: Center(child: Icon(mealIcon(t), color: Colors.white, size: 64)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          Chip(avatar: const Icon(Icons.local_fire_department, size: 18), label: Text('${recipe['kcal']} kkal')),
          Chip(avatar: const Icon(Icons.timer, size: 18), label: Text('${recipe['prep_minutes']} daqiqa')),
          Chip(label: Text(mealTypeLabels[t] ?? '')),
        ]),
        const SizedBox(height: 12),
        Text("Masalliqlar", style: Theme.of(context).textTheme.titleMedium),
        for (final i in ingredients) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•  '), Expanded(child: Text(i))])),
        const SizedBox(height: 12),
        Text("Tayyorlash", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(recipe['instructions'] as String),
        const SizedBox(height: 12),
        const Text("Kaloriya taxminiy.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text("Bugungi ovqatga qo'shish")),
      ]),
    );
  }
}

/// Retseptsiz o'z ovqatini qo'shish
Future<bool> addCustomMeal(BuildContext context) async {
  final title = TextEditingController(), kcal = TextEditingController();
  var type = 'lunch';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text("Ovqat qo'shish"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: "Ovqat nomi")),
          const SizedBox(height: 8),
          TextField(controller: kcal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Kaloriya (kkal)")),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: type,
            isExpanded: true,
            items: [for (final e in mealTypeLabels.entries.where((e) => e.key != 'detox')) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setS(() => type = v ?? type),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Bekor qilish")),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(80, 40)), onPressed: () => Navigator.pop(ctx, true), child: const Text("Qo'shish")),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  final k = int.tryParse(kcal.text.trim());
  if (title.text.trim().isEmpty || k == null || k < 0 || k > 5000) {
    toast(context, "Nom va kaloriya (0–5000) to'g'ri kiritilsin");
    return false;
  }
  try {
    await _api(context).post('/meals', body: {'title': title.text.trim(), 'kcal': k, 'meal_type': type});
    return true;
  } on ApiException catch (e) {
    toast(context, e.message);
    return false;
  }
}
