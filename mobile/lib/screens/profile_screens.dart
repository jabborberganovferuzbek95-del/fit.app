import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../models.dart';
import '../navigation.dart';
import '../ui.dart';
import 'assistant_screens.dart';
import 'wellness_screens.dart';

ApiClient _api(BuildContext c) => c.read<AppState>().api;

// ======================= Profil formasi (sozlamalar uchun) =======================
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.initial, required this.buttonLabel, this.onSaved});
  final Map<String, dynamic> initial;
  final String buttonLabel;
  final VoidCallback? onSaved;
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  String? _goal, _level, _loc, _activity;
  double _minutes = 30;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _goal = widget.initial['goal'];
    _level = widget.initial['experience_level'];
    _loc = widget.initial['preferred_location'];
    _activity = widget.initial['activity_level'];
    _minutes = ((widget.initial['daily_minutes'] ?? 30) as int).clamp(5, 120).toDouble();
  }

  Widget _drop(String label, Map<String, String> items, String? value, ValueChanged<String?> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(labelText: label),
          items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: onChanged,
        ),
      );

  Future<void> _save() async {
    if (_goal == null || _level == null || _loc == null) return setState(() => _error = "Maqsad, daraja va joyni tanlang");
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<AppState>().updateMe({
        'goal': _goal, 'experience_level': _level, 'preferred_location': _loc, 'daily_minutes': _minutes.round(),
        if (_activity != null) 'activity_level': _activity,
      });
      if (mounted) {
        toast(context, "Profil saqlandi");
        widget.onSaved?.call();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _drop("Maqsad", goalLabels, _goal, (v) => setState(() => _goal = v)),
        _drop("Tajriba darajasi", levelLabels, _level, (v) => setState(() => _level = v)),
        _drop("Qayerda mashq qilasiz", locationLabels, _loc, (v) => setState(() => _loc = v)),
        _drop("Faollik darajasi", activityLabels, _activity, (v) => setState(() => _activity = v)),
        Text("Kuniga mavjud vaqt: ${_minutes.round()} daqiqa"),
        Slider(value: _minutes, min: 5, max: 120, divisions: 23, label: '${_minutes.round()}', onChanged: (v) => setState(() => _minutes = v)),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        FilledButton(onPressed: _busy ? null : _save, child: Text(widget.buttonLabel)),
      ]);
}

// ======================= Birinchi sozlash: 2 qadam =======================
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 0;
  String? _goal, _loc = 'mixed', _level = 'beginner', _activity = 'moderate';
  double _minutes = 30;
  bool _busy = false;
  String? _error;

  Future<void> _finish() async {
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<AppState>().updateMe({
        'goal': _goal, 'experience_level': _level, 'preferred_location': _loc, 'daily_minutes': _minutes.round(), 'activity_level': _activity,
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Widget _choice(String title, String? sub, bool selected, VoidCallback onTap, {IconData? icon}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? kGreen : Colors.transparent, width: 2)),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            if (icon != null) ...[Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: kGreen)), const SizedBox(width: 14)],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), if (sub != null) Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
            if (selected) const Icon(Icons.check_circle, color: kGreen),
          ]),
        ),
      );

  Widget _chips(Map<String, String> items, String? value, ValueChanged<String> onSel) => Wrap(spacing: 8, runSpacing: 4, children: [
        for (final e in items.entries) ChoiceChip(label: Text(e.value), selected: value == e.key, onSelected: (_) => onSel(e.key)),
      ]);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        leading: _step == 1 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 0)) : null,
        title: Row(children: [for (var i = 0; i < 2; i++) Expanded(child: Container(margin: const EdgeInsets.only(right: 6), height: 4, decoration: BoxDecoration(color: i <= _step ? kGreen : Colors.grey.shade400, borderRadius: BorderRadius.circular(2))))]),
        actions: [TextButton(onPressed: app.logout, child: const Text("Chiqish"))],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: _step == 0
                ? [
                    const Text("Asosiy maqsadingiz nima?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Sizga mos tavsiyalar uchun maqsadingizni tanlang.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    for (final g in setupGoals) _choice(goalLabels[g]!, null, _goal == g, () => setState(() => _goal = g), icon: goalIcon(g)),
                  ]
                : [
                    const Text("Qulay sozlamalar", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Vazn, bo'y va yosh so'ralmaydi: faqat mashqlarni moslash uchun kerakli narsalar.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    const Text("Qayerda mashq qilasiz?", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _chips(locationLabels, _loc, (v) => setState(() => _loc = v)),
                    const SizedBox(height: 14),
                    const Text("Tajriba darajasi", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _chips(levelLabels, _level, (v) => setState(() => _level = v)),
                    const SizedBox(height: 14),
                    const Text("Faollik darajasi", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final a in activityLabels.entries) _choice(a.value, activityHints[a.key], _activity == a.key, () => setState(() => _activity = a.key)),
                    const SizedBox(height: 6),
                    Text("Kuniga mavjud vaqt: ${_minutes.round()} daqiqa", style: const TextStyle(fontWeight: FontWeight.w600)),
                    Slider(value: _minutes, min: 5, max: 120, divisions: 23, label: '${_minutes.round()}', onChanged: (v) => setState(() => _minutes = v)),
                    const SafetyBanner(),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: _busy || (_step == 0 && _goal == null) ? null : () => _step == 0 ? setState(() => _step = 1) : _finish(),
              child: Text(_step == 0 ? "Davom etish" : "Boshlash"),
            ),
          ),
        ]),
      ),
    );
  }
}

// ======================= Mening profilim (tab) =======================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _menu(BuildContext context, IconData icon, Color color, String title, String sub, Widget page, {bool modal = false}) => AppCard(
        onTap: () => modal ? AppNav.pushSlideUp(context, page) : AppNav.pushSharedAxis(context, page),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          const Icon(Icons.chevron_right),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me!;
    final name = (me.fullName ?? '').trim().isNotEmpty ? me.fullName! : me.email.split('@').first;
    return Scaffold(
      appBar: AppBar(title: const Text("Mening profilim"), actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => AppNav.pushSharedAxis(context, const SettingsScreen()))]),
      body: Loader<Map<String, dynamic>>(
        load: () => _api(context).getMap('/me/summary'),
        builder: (context, s, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Hero(
                tag: 'user-avatar',
                child: Material(
                  type: MaterialType.transparency,
                  child: CircleAvatar(radius: 34, backgroundColor: kGreen, child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(goalLabels[me.profile['goal']] ?? "Sog'lom hayot yo'lida", style: const TextStyle(color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              StatTile("Seanslar", '${s['sessions_total']}', icon: Icons.fitness_center),
              StatTile("Faol kun (30 kun)", '${s['active_days_30']}', icon: Icons.calendar_month),
              StatTile("Seriya", '${s['streak']} kun', icon: Icons.local_fire_department, color: Colors.orange),
            ]),
            const SizedBox(height: 4),
            _menu(context, Icons.flag, kGreen, "Maqsadlarim", "Qadam, suv, uyqu, mashq, kaloriya", const GoalsScreen()),
            _menu(context, Icons.emoji_events, Colors.amber.shade700, "Yutuqlar", "Medallar va natijalar", const AchievementsScreen()),
            _menu(context, Icons.notifications_none, Colors.blue, "Bildirishnomalar", "Maslahatlar va tizim xabarlari", const NotificationsScreen(), modal: true),
            _menu(context, Icons.chat_bubble_outline, Colors.teal, "Maslahatchi", "Qoidalarga asoslangan (AI emas)", const CoachScreen(), modal: true),
            _menu(context, Icons.workspace_premium, Colors.amber, "Premium", "Tez orada", const PremiumScreen(), modal: true),
            _menu(context, Icons.settings, Colors.blueGrey, "Sozlamalar", "Profil, mavzu, maxfiylik", const SettingsScreen()),
          ]),
        ),
      ),
    );
  }
}

// ======================= Sozlamalar =======================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _item(BuildContext context, IconData icon, String title, Widget page) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => AppNav.pushSharedAxis(context, page),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text("Sozlamalar")),
      body: ListView(children: [
        _item(context, Icons.person_outline, "Profil ma'lumotlari", const EditProfileScreen()),
        _item(context, Icons.flag_outlined, "Maqsadlar", const GoalsScreen()),
        const SwitchListTile(secondary: Icon(Icons.notifications_none), title: Text("Bildirishnomalar"), subtitle: Text("Telefon eslatmalari keyingi versiyada"), value: false, onChanged: null),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text("Ilova tili"),
          trailing: DropdownButton<String>(
            value: 'uz',
            items: const [DropdownMenuItem(value: 'uz', child: Text("O'zbekcha")), DropdownMenuItem(value: 'ru', child: Text("Русский (tez orada)")), DropdownMenuItem(value: 'en', child: Text("English (tez orada)"))],
            onChanged: (v) { if (v != 'uz') toast(context, "Bu til keyingi versiyada qo'shiladi"); },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text("Mavzu"),
          trailing: DropdownButton<ThemeMode>(
            value: app.themeMode,
            items: const [DropdownMenuItem(value: ThemeMode.system, child: Text("Tizim")), DropdownMenuItem(value: ThemeMode.light, child: Text("Yorug'")), DropdownMenuItem(value: ThemeMode.dark, child: Text("Qorong'i"))],
            onChanged: (v) { if (v != null) app.setThemeMode(v); },
          ),
        ),
        _item(context, Icons.privacy_tip_outlined, "Maxfiylik va xavfsizlik", const PrivacyScreen()),
        _item(context, Icons.help_outline, "Yordam va qo'llab-quvvatlash", const HelpScreen()),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text("Ilova haqida"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: "FitHayot 360",
            applicationVersion: "3.0.0",
            children: const [Text("Home, Gym va Active mashg'ulotlari, ovqatlanish, suv, uyqu, meditatsiya va odatlarni bitta hisobda yuritish. Ilova tibbiy maslahat bermaydi va sun'iy intellekt ishlatmaydi. 18 yosh va undan kattalar uchun.")],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Chiqish", style: TextStyle(color: Colors.red)),
          onTap: () async { if (await confirm(context, "Chiqish", "Hisobdan chiqasizmi?")) app.logout(); },
        ),
      ]),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: context.read<AppState>().me?.fullName ?? '');
  bool _busy = false;

  Future<void> _saveName() async {
    if (_name.text.trim().isEmpty) return toast(context, "Ismni kiriting");
    setState(() => _busy = true);
    try {
      await context.read<AppState>().updateMe({'full_name': _name.text.trim()});
      if (mounted) toast(context, "Ism saqlandi");
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me!;
    return Scaffold(
      appBar: AppBar(title: const Text("Profil ma'lumotlari")),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: "Ism va familiya", suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: _busy ? null : _saveName))),
        const SizedBox(height: 8),
        Text(me.email, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        ProfileForm(initial: me.profile, buttonLabel: "Saqlash"),
      ]),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      final s = await _api(context).getMap('/me/export');
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Ma'lumotlaringiz tayyor"),
          content: Text("Hisobingizda: ${(s['sessions'] as List).length} ta seans, ${(s['activities'] as List).length} ta faollik, ${(s['plans'] as List).length} ta reja.\n\nTo'liq JSON fayl yuborish keyingi versiyada qo'shiladi (hozircha /me/export API orqali olinadi)."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Yopish"))],
        ),
      );
    } catch (e) {
      toast(context, errMsg(e));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hisobni o'chirish"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Barcha rejalar, seanslar, suv, uyqu, ovqat va boshqa qaydlar qaytarib bo'lmas tarzda o'chiriladi. Tasdiqlash uchun parolingizni kiriting."),
          const SizedBox(height: 12),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: "Parol")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Bekor qilish")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("O'chirish", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final app = context.read<AppState>();
      await app.api.delete('/me', body: {'password': pass.text});
      await app.logout();
    } catch (e) {
      toast(context, errMsg(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Maxfiylik va xavfsizlik")),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Qanday ma'lumotlar saqlanadi", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Email va ism, maqsad va sozlamalar, siz kiritgan mashq, faollik, suv, uyqu, qadam, ovqat va meditatsiya qaydlari. Parol shifrlangan holda (bcrypt) saqlanadi."),
            SizedBox(height: 10),
            Text("Nimalar so'ralmaydi", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Vazn, bo'y, yosh, kasalliklar, joylashuv (GPS) va kontaktlar. Ma'lumotlar reklama uchun sotilmaydi."),
          ])),
          ListTile(leading: const Icon(Icons.download_outlined), title: const Text("Ma'lumotlarimni eksport qilish"), onTap: () => _export(context)),
          ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text("Hisobni o'chirish", style: TextStyle(color: Colors.red)), onTap: () => _delete(context)),
        ]),
      );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  static const _faq = [
    ("Qadamlar qanday hisoblanadi?", "Ilova qadamni avtomatik sanamaydi. Bosh sahifadagi kartani bosib, telefon yoki soatingizdagi sonni kiriting."),
    ("Kaloriya qiymatlari aniqmi?", "Retseptlardagi kaloriya taxminiy. Ilova yoqilgan kaloriyani hisoblamaydi va dietolog maslahatini almashtirmaydi."),
    ("Maslahatchi sun'iy intellektmi?", "Yo'q. U sizning ma'lumotlaringiz va oddiy qoidalar asosida tavsiya beradi."),
    ("Ma'lumotlarimni qanday o'chiraman?", "Sozlamalar → Maxfiylik va xavfsizlik → Hisobni o'chirish."),
    ("Ilova shifokor o'rnini bosadimi?", "Yo'q. Og'riq, bosh aylanishi yoki nafas qisilishi sezsangiz, mashqni to'xtating va shifokorga murojaat qiling."),
    ("Telefon eslatmalari bormi?", "Hozircha yo'q, keyingi versiyada rejalashtirilgan. Ilova ichidagi maslahatlar Bildirishnomalar bo'limida."),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Yordam va qo'llab-quvvatlash")),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final q in _faq)
            AppCard(padding: EdgeInsets.zero, child: ExpansionTile(shape: const Border(), title: Text(q.$1, style: const TextStyle(fontWeight: FontWeight.w600)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14), expandedAlignment: Alignment.centerLeft, children: [Text(q.$2)])),
          const SizedBox(height: 8),
          const SafetyBanner(),
        ]),
      );
}
