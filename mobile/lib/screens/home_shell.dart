import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../motion.dart';
import '../navigation.dart';
import '../ui.dart';
import 'active_screen.dart';
import 'assistant_screens.dart';
import 'catalog_screens.dart';
import 'meditation_screens.dart';
import 'nutrition_screens.dart';
import 'planner_screens.dart';
import 'profile_screens.dart';
import 'session_screens.dart';
import 'stats_screen.dart';
import 'wellness_screens.dart';

/// Tanlangan tab ikonkasi uchun silliq "pop" animatsiyasi (1.0 -> 1.14 -> 1.0)
class _PopIcon extends StatefulWidget {
  const _PopIcon({required this.icon, required this.selected});
  final IconData icon;
  final bool selected;

  @override
  State<_PopIcon> createState() => _PopIconState();
}

class _PopIconState extends State<_PopIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scaleAnimation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant _PopIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Icon(widget.icon);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(widget.icon),
    );
  }
}

/// Tablar almashganda 210 ms fade-in va 8 dp pastdan ko'tarilish harakati
class _TabFadeWrapper extends StatefulWidget {
  const _TabFadeWrapper({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<_TabFadeWrapper> createState() => _TabFadeWrapperState();
}

class _TabFadeWrapperState extends State<_TabFadeWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 210),
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 8),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  ));

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _TabFadeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.translate(
          offset: _slideAnimation.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Pastki navigatsiya: Bosh sahifa, Mashqlar, Ovqatlanish, Statistika, Profil
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;
  final Set<int> _loadedTabs = {0};
  final ScrollController _dashScroll = ScrollController();
  DateTime? _lastBackTime;

  @override
  void dispose() {
    _dashScroll.dispose();
    super.dispose();
  }

  void _handlePop(bool didPop, dynamic result) {
    if (didPop) return;
    if (_i != 0) {
      _onSelect(0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackTime == null || now.difference(_lastBackTime!) > const Duration(seconds: 2)) {
      _lastBackTime = now;
      toast(context, "Chiqish uchun yana bir marta bosing");
      return;
    }
    SystemNavigator.pop();
  }

  void _onSelect(int v) {
    if (v == _i) {
      if (v == 0 && _dashScroll.hasClients) {
        _dashScroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      }
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _loadedTabs.add(v);
      _i = v;
    });
  }

  Widget _buildTab(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    final child = switch (index) {
      0 => DashboardScreen(
          scrollController: _dashScroll,
          onTab: _onSelect,
        ),
      1 => const CatalogScreen(),
      2 => const NutritionScreen(),
      3 => const StatsScreen(),
      _ => const ProfileScreen(),
    };
    return _TabFadeWrapper(
      key: ValueKey(index),
      active: _i == index,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        body: IndexedStack(
          index: _i,
          children: [for (var k = 0; k < 5; k++) _buildTab(k)],
        ),
        bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: _onSelect,
        destinations: [
          NavigationDestination(
            icon: _PopIcon(icon: Icons.home_outlined, selected: _i == 0),
            selectedIcon: _PopIcon(icon: Icons.home, selected: _i == 0),
            label: "Bosh sahifa",
          ),
          NavigationDestination(
            icon: _PopIcon(icon: Icons.fitness_center, selected: _i == 1),
            label: "Mashqlar",
          ),
          NavigationDestination(
            icon: _PopIcon(icon: Icons.restaurant_menu, selected: _i == 2),
            label: "Ovqatlanish",
          ),
          NavigationDestination(
            icon: _PopIcon(icon: Icons.bar_chart, selected: _i == 3),
            label: "Statistika",
          ),
          NavigationDestination(
            icon: _PopIcon(icon: Icons.person_outline, selected: _i == 4),
            selectedIcon: _PopIcon(icon: Icons.person, selected: _i == 4),
            label: "Profil",
          ),
        ],
      ),
    ),
  );
  }
}

class _Dash {
  _Dash(this.t, this.today, {this.hasInsights = false});
  final Map<String, dynamic> t;
  final List<(Plan, PlanItem)> today;
  final bool hasInsights;
}

/// Bosh sahifa: qadam kartasi, bo'limlar, bugungi reja
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onTab, this.scrollController});
  final void Function(int) onTab;
  final ScrollController? scrollController;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _epoch = 0;

  Future<_Dash> _load() async {
    final api = context.read<AppState>().api;
    final results = await Future.wait([
      api.getMap('/dashboard/today'),
      api.get('/plans'),
      api.getList('/insights').catchError((_) => <Map<String, dynamic>>[]),
    ]);
    final now = DateTime.now();
    final plans = (results[1] as List).map((e) => Plan.fromJson(Map<String, dynamic>.from(e))).where((p) => p.status == 'active' && p.covers(now));
    final full = await Future.wait(plans.map((p) async => Plan.fromJson(Map<String, dynamic>.from(await api.get('/plans/${p.id}')))));
    final insights = results[2] as List;
    return _Dash(
      results[0] as Map<String, dynamic>,
      [for (final p in full) for (final i in p.items) if (sameDay(i.date, now)) (p, i)],
      hasInsights: insights.isNotEmpty,
    );
  }

  Future<void> _go(Widget page, Future<void> Function() reload, {NavTransition transition = NavTransition.sharedAxis}) async {
    await AppNav.pushAndRefresh(context, page, onReturn: reload, transition: transition);
  }

  Future<void> _start(String mode, Future<void> Function() reload, {Plan? plan, PlanItem? item}) async {
    await startSession(context, mode, plan: plan, item: item);
    await reload();
  }

  Widget _dayStrip() {
    final now = DateTime.now();
    final mon = mondayOf(now);
    return Row(children: [
      for (var i = 0; i < 7; i++)
        Expanded(
          child: Column(children: [
            Text(weekdaysShort[i], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              width: 36, height: 36, alignment: Alignment.center,
              decoration: sameDay(mon.add(Duration(days: i)), now) ? BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(12)) : null,
              child: Text('${mon.add(Duration(days: i)).day}', style: TextStyle(fontWeight: FontWeight.w600, color: sameDay(mon.add(Duration(days: i)), now) ? Colors.white : null)),
            ),
          ]),
        ),
    ]);
  }

  Widget _stat(IconData icon, String value, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, color: kMint, size: 20),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      );

  Widget _tile(String title, String sub, IconData icon, Color color, VoidCallback onTap) => PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AppState>().me?.email ?? '';
    final fullName = context.watch<AppState>().me?.fullName;
    final name = (fullName ?? '').trim().isNotEmpty ? fullName!.trim() : email.split('@').first;
    return Scaffold(
      body: SafeArea(
        child: Loader<_Dash>(
          key: ValueKey(_epoch),
          load: _load,
          builder: (context, d, reload) {
            final t = d.t;
            final goals = Map<String, dynamic>.from(t['goals']);
            final steps = t['steps'] as int, stepGoal = goals['steps'] as int;
            final water = t['water_ml'] as int, sleep = t['sleep_min'] as int, meditation = t['meditation_min'] as int;
            if (steps >= stepGoal && stepGoal > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) triggerDailyCelebration(context, 'steps');
              });
            }
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => widget.onTab(4),
                      child: Hero(
                        tag: 'user-avatar',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: kGreen,
                            child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Salom, $name!", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Text("Bugun ham sog'lom hayot sari qadam!", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ])),
                    IconButton(tooltip: "Maslahatchi", icon: const Icon(Icons.chat_bubble_outline), onPressed: () => _go(const CoachScreen(), reload, transition: NavTransition.slideUp)),
                    IconButton(
                      tooltip: "Bildirishnomalar",
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none),
                          if (d.hasInsights)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => _go(const NotificationsScreen(), reload, transition: NavTransition.slideUp),
                    ),
                  ]),
                const SizedBox(height: 16),
                _dayStrip(),
                const SizedBox(height: 16),
                FadeSlideIn(delay: const Duration(milliseconds: 0), child: GestureDetector(
                  onTap: () async {
                    if (await editSteps(context, steps)) await reload();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [kGreen, kGreenDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: Column(children: [
                      Row(children: [
                        RingProgress(
                          value: stepGoal == 0 ? 0 : steps / stepGoal, size: 130, stroke: 11, color: kMint,
                          semanticsLabel: "Bugungi qadamlar",
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(fmtInt(steps), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text("qadam", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ]),
                        ),
                        const SizedBox(width: 22),
                        Expanded(child: Column(children: [
                          _stat(Icons.timer, '${t['active_minutes']} daq', "Faol vaqt"),
                          _stat(Icons.restaurant, '${fmtInt(t['calories_in'] as int)} kkal', "Iste'mol qilingan"),
                          _stat(Icons.bedtime, sleep > 0 ? fmtSleep(sleep) : "—", "Uyqu"),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      Text("Maqsad: ${fmtInt(stepGoal)} qadam · o'zgartirish uchun bosing", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                )),
                const SizedBox(height: 16),
                FadeSlideIn(delay: const Duration(milliseconds: 90), child: GridView.count(
                  crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.95,
                  children: [
                    _tile("Mashqlar", "Uyda va zalda", Icons.fitness_center, Colors.red, () => widget.onTab(1)),
                    _tile("Ovqatlanish", '${t['calories_in']} / ${fmtInt(goals['calories'] as int)} kkal', Icons.restaurant_menu, Colors.green, () => widget.onTab(2)),
                    _tile("Suv", '${fmtL(water)} / ${fmtL(goals['water_ml'] as int)} L', Icons.water_drop, Colors.lightBlue, () => _go(const WaterScreen(), reload)),
                    _tile("Uyqu", sleep > 0 ? fmtSleep(sleep) : "Qayd yo'q", Icons.bedtime, Colors.deepPurple, () => _go(const SleepScreen(), reload)),
                    _tile("Meditatsiya", meditation > 0 ? '$meditation daq' : "Tinchlaning", Icons.self_improvement, Colors.pink, () => _go(const MeditationScreen(), reload)),
                    _tile("Odatlar", '${t['habits_done']}/${(t['habits'] as List).length} bajarildi', Icons.checklist, Colors.orange, () => _go(const HabitsScreen(), reload)),
                  ],
                )),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: FilledButton.tonalIcon(onPressed: () => _start('home', reload), icon: const Icon(Icons.home_rounded), label: const Text("Home"))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.tonalIcon(onPressed: () => _start('gym', reload), icon: const Icon(Icons.fitness_center), label: const Text("Gym"))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.tonalIcon(onPressed: () => _go(const ActiveScreen(), reload), icon: const Icon(Icons.directions_walk), label: const Text("Faollik"))),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Text("Bugungi reja", style: Theme.of(context).textTheme.titleMedium)),
                  TextButton(onPressed: () => _go(const PlannerScreen(), reload), child: const Text("Haftalik reja")),
                ]),
                if (d.today.isEmpty) const AppCard(child: Text("Bugun uchun reja yo'q. \"Mashqlar\" bo'limidan mashq tanlab rejaga qo'shing yoki seansni to'g'ridan-to'g'ri boshlang.")),
                for (final (plan, item) in d.today)
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(children: [
                      item.isCompleted ? const Icon(Icons.check_circle, color: Colors.green, size: 32) : ModuleBadge(item.exercise.mode),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.exercise.title, style: const TextStyle(fontWeight: FontWeight.w600)), Text('${modeLabels[item.exercise.mode]} · ${item.minutes} daqiqa', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
                      if (!item.isCompleted) IconButton(icon: const Icon(Icons.play_circle_fill, size: 34, color: kGreen), onPressed: () => _start(item.exercise.mode, reload, plan: plan, item: item)),
                    ]),
                  ),
                const SizedBox(height: 8),
                const SafetyBanner(),
              ]),
            );
          },
        ),
      ),
    );
  }
}
