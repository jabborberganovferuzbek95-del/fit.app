import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../motion.dart';
import '../navigation.dart';
import '../ui.dart';

/// S01 Splash
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error});
  final String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kGreenDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.favorite, size: 72, color: kMint),
              const SizedBox(height: 12),
              Text("FitHayot 360", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              if (error == null)
                const CircularProgressIndicator()
              else ...[
                Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: () => context.read<AppState>().init(), child: const Text("Qayta urinish")),
              ],
            ]),
          ),
        ),
      );
}

/// S02 Onboarding: 1) hero  2) imkoniyatlar ro'yxati
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _c = PageController();
  int _page = 0;

  static const _features = [
    (Icons.fitness_center, "Mashqlar va trenirovkalar"),
    (Icons.restaurant_menu, "Ovqatlanish va ratsion"),
    (Icons.water_drop, "Suv kuzatuvi"),
    (Icons.bedtime, "Uyqu va dam olish"),
    (Icons.self_improvement, "Meditatsiya va nafas mashqlari"),
    (Icons.checklist, "Sog'lom odatlar"),
    (Icons.bar_chart, "Statistika va tahlil"),
    (Icons.person_pin, "Shaxsiy tavsiyalar"),
  ];

  Future<void> _create() async {
    final app = context.read<AppState>();
    await app.finishOnboarding();
    if (mounted) AppNav.pushFade(context, const RegisterScreen());
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == 1;
    return Scaffold(
      backgroundColor: kGreenDark,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _c,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 64, height: 64, decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.eco, color: kGreenDark, size: 36)),
                    const SizedBox(height: 20),
                    const Text("Sog'lom", style: TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.bold, height: 1.05)),
                    const Text("Hayot", style: TextStyle(color: kMint, fontSize: 46, fontWeight: FontWeight.bold, height: 1.05)),
                    const SizedBox(height: 16),
                    const Text("Sog'lom tana, baxtli hayot!\nHar kuni yaxshiroq versiyangizga yaqinlashing.", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 20),
                  ]),
                ),
                ListView(padding: const EdgeInsets.fromLTRB(28, 40, 28, 12), children: [
                  const Icon(Icons.self_improvement, color: kMint, size: 72),
                  const SizedBox(height: 16),
                  const Text("Sog'lom hayot uchun barcha imkoniyatlar bitta ilovada", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  for (final f in _features)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)), child: Icon(f.$1, color: kMint, size: 20)),
                        const SizedBox(width: 14),
                        Text(f.$2, style: const TextStyle(color: Colors.white, fontSize: 15)),
                      ]),
                    ),
                  const SizedBox(height: 12),
                  const Text("Ilova 18 yosh va undan kattalar uchun. U tibbiy maslahat bermaydi; sog'liq savollari uchun shifokorga murojaat qiling.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 2; i++)
              Container(margin: const EdgeInsets.all(4), width: i == _page ? 20 : 8, height: 8, decoration: BoxDecoration(color: i == _page ? kMint : Colors.white24, borderRadius: BorderRadius.circular(4))),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kMint, foregroundColor: Colors.black),
              onPressed: () => last ? _create() : _c.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
              child: Text(last ? "Hisob yaratish" : "Boshlash  →"),
            ),
          ),
          TextButton(
            onPressed: context.read<AppState>().finishOnboarding,
            child: const Text.rich(TextSpan(text: "Hisobingiz bormi? ", style: TextStyle(color: Colors.white70), children: [TextSpan(text: "Kirish", style: TextStyle(color: kMint, fontWeight: FontWeight.bold))])),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

String? _emailRule(String? v) {
  final s = (v ?? '').trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return "To'g'ri email kiriting";
  return null;
}

String? _passRule(String? v) {
  final s = v ?? '';
  if (s.length < 8) return "Parol kamida 8 belgi bo'lsin";
  if (!s.contains(RegExp(r'[A-Za-z]')) || !s.contains(RegExp(r'[0-9]'))) return "Parolda harf va raqam bo'lsin";
  return null;
}

/// S04 Kirish
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _email = TextEditingController(), _pass = TextEditingController();
  bool _busy = false, _hide = true;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<AppState>().login(_email.text.trim(), _pass.text);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        _shakeKey.currentState?.shake();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ShakeWidget(
                key: _shakeKey,
                child: Form(
                  key: _form,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Icon(Icons.favorite, size: 56, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text("Kirish", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),
                    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: "Email"), validator: _emailRule),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: _hide,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: "Parol", suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hide = !_hide))),
                      validator: (v) => (v ?? '').isEmpty ? "Parolni kiriting" : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Kirish")),
                    TextButton(onPressed: () => AppNav.pushFade(context, const ForgotPasswordScreen()), child: const Text("Parolni unutdingizmi?")),
                    OutlinedButton(onPressed: () => AppNav.pushFade(context, const RegisterScreen()), child: const Text("Ro'yxatdan o'tish")),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

/// S03 Ro'yxatdan o'tish (18+ va rozilik majburiy — FR-01)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController(), _pass2 = TextEditingController();
  bool _adult = false, _terms = false, _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }
    if (!_adult) {
      _shakeKey.currentState?.shake();
      return setState(() => _error = "Davom etish uchun 18 yosh va undan katta ekaningizni tasdiqlang");
    }
    if (!_terms) {
      _shakeKey.currentState?.shake();
      return setState(() => _error = "Foydalanish shartlari va maxfiylik siyosatiga rozilik bering");
    }
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<AppState>().register(_email.text.trim(), _pass.text, fullName: _name.text);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        _shakeKey.currentState?.shake();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Ro'yxatdan o'tish")),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ShakeWidget(
              key: _shakeKey,
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text("Hisob yaratish", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text("Sog'lom hayotingiz shu yerdan boshlanadi!", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: "Ism va familiya", prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v ?? '').trim().length < 2 ? "Ismingizni kiriting" : null),
                const SizedBox(height: 12),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.mail_outline)), validator: _emailRule),
                const SizedBox(height: 12),
                TextFormField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Parol", helperText: "Kamida 8 belgi, harf va raqam"), validator: _passRule),
                const SizedBox(height: 12),
                TextFormField(controller: _pass2, obscureText: true, decoration: const InputDecoration(labelText: "Parolni takrorlang"), validator: (v) => v != _pass.text ? "Parollar mos kelmadi" : null),
                const SizedBox(height: 8),
                CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: _adult, onChanged: (v) => setState(() => _adult = v ?? false), title: const Text("Men 18 yosh va undan kattaman")),
                CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), title: const Text("Foydalanish shartlari va maxfiylik siyosatiga roziman. Faqat zarur ma'lumotlar yig'iladi; ularni istalgan vaqtda eksport qilish yoki o'chirish mumkin.", style: TextStyle(fontSize: 13))),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 16),
                FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Hisob ochish")),
              ]),
              ),
            ),
          ),
        ),
      );
}

/// S04 Parolni tiklash
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController(), _token = TextEditingController(), _pass = TextEditingController();
  bool _sent = false, _busy = false;
  String? _info, _error;

  Future<void> _run(Future<void> Function() f) async {
    setState(() { _busy = true; _error = null; });
    try {
      await f();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        if (_emailRule(_email.text) != null) throw ApiException(422, "To'g'ri email kiriting");
        final api = context.read<AppState>().api;
        final j = await api.post('/auth/forgot-password', body: {'email': _email.text.trim()}, auth: false);
        setState(() {
          _sent = true;
          _info = j['message'];
          if (j['reset_token'] != null) _token.text = j['reset_token']; // faqat development rejimida
        });
      });

  Future<void> _reset() => _run(() async {
        final rule = _passRule(_pass.text);
        if (rule != null) throw ApiException(422, rule);
        await context.read<AppState>().api.post('/auth/reset-password', body: {'token': _token.text.trim(), 'new_password': _pass.text}, auth: false);
        if (!mounted) return;
        toast(context, "Parol yangilandi. Endi kiring.");
        Navigator.pop(context);
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Parolni tiklash")),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(controller: _email, enabled: !_sent, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Email")),
              const SizedBox(height: 12),
              if (!_sent) FilledButton(onPressed: _busy ? null : _send, child: const Text("Tiklash kodini yuborish")),
              if (_sent) ...[
                if (_info != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_info!)),
                TextField(controller: _token, decoration: const InputDecoration(labelText: "Tiklash kodi (emaildan)")),
                const SizedBox(height: 12),
                TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Yangi parol")),
                const SizedBox(height: 12),
                FilledButton(onPressed: _busy ? null : _reset, child: const Text("Parolni yangilash")),
              ],
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            ]),
          ),
        ),
      );
}
