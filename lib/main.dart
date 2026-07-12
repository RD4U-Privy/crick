import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(CrickApp(store: await PlayerStore.create()));
}

final class PlayerData {
  const PlayerData({
    this.coins = 250,
    this.games = 0,
    this.highScore = 0,
    this.totalScore = 0,
    this.fours = 0,
    this.sixes = 0,
    this.perfects = 0,
    this.shots = 0,
    this.hits = 0,
    this.longestCombo = 0,
    this.selectedBat = 0,
    this.selectedBall = 0,
    this.selectedStadium = 0,
    this.unlockedBats = const <int>{0},
    this.unlockedBalls = const <int>{0},
    this.unlockedStadiums = const <int>{0},
    this.sound = true,
    this.haptics = true,
    this.lastRewardDay = '',
    this.loginStreak = 0,
  });

  final int coins, games, highScore, totalScore, fours, sixes, perfects, shots, hits;
  final int longestCombo, selectedBat, selectedBall, selectedStadium, loginStreak;
  final Set<int> unlockedBats, unlockedBalls, unlockedStadiums;
  final bool sound, haptics;
  final String lastRewardDay;

  double get averageScore => games == 0 ? 0 : totalScore / games;
  double get accuracy => shots == 0 ? 0 : hits / shots;

  PlayerData copyWith({
    int? coins,
    int? games,
    int? highScore,
    int? totalScore,
    int? fours,
    int? sixes,
    int? perfects,
    int? shots,
    int? hits,
    int? longestCombo,
    int? selectedBat,
    int? selectedBall,
    int? selectedStadium,
    Set<int>? unlockedBats,
    Set<int>? unlockedBalls,
    Set<int>? unlockedStadiums,
    bool? sound,
    bool? haptics,
    String? lastRewardDay,
    int? loginStreak,
  }) => PlayerData(
    coins: coins ?? this.coins,
    games: games ?? this.games,
    highScore: highScore ?? this.highScore,
    totalScore: totalScore ?? this.totalScore,
    fours: fours ?? this.fours,
    sixes: sixes ?? this.sixes,
    perfects: perfects ?? this.perfects,
    shots: shots ?? this.shots,
    hits: hits ?? this.hits,
    longestCombo: longestCombo ?? this.longestCombo,
    selectedBat: selectedBat ?? this.selectedBat,
    selectedBall: selectedBall ?? this.selectedBall,
    selectedStadium: selectedStadium ?? this.selectedStadium,
    unlockedBats: unlockedBats ?? this.unlockedBats,
    unlockedBalls: unlockedBalls ?? this.unlockedBalls,
    unlockedStadiums: unlockedStadiums ?? this.unlockedStadiums,
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    lastRewardDay: lastRewardDay ?? this.lastRewardDay,
    loginStreak: loginStreak ?? this.loginStreak,
  );

  String encode() => jsonEncode(<String, Object>{
    'coins': coins,
    'games': games,
    'highScore': highScore,
    'totalScore': totalScore,
    'fours': fours,
    'sixes': sixes,
    'perfects': perfects,
    'shots': shots,
    'hits': hits,
    'longestCombo': longestCombo,
    'selectedBat': selectedBat,
    'selectedBall': selectedBall,
    'selectedStadium': selectedStadium,
    'unlockedBats': unlockedBats.toList(),
    'unlockedBalls': unlockedBalls.toList(),
    'unlockedStadiums': unlockedStadiums.toList(),
    'sound': sound,
    'haptics': haptics,
    'lastRewardDay': lastRewardDay,
    'loginStreak': loginStreak,
  });

  factory PlayerData.decode(String source) {
    final Map<String, Object?> data = jsonDecode(source) as Map<String, Object?>;
    int number(String key, [int fallback = 0]) => (data[key] as num?)?.toInt() ?? fallback;
    Set<int> numbers(String key) => ((data[key] as List<Object?>?) ?? <Object?>[0])
        .map((Object? value) => (value as num).toInt())
        .toSet();
    return PlayerData(
      coins: number('coins', 250),
      games: number('games'),
      highScore: number('highScore'),
      totalScore: number('totalScore'),
      fours: number('fours'),
      sixes: number('sixes'),
      perfects: number('perfects'),
      shots: number('shots'),
      hits: number('hits'),
      longestCombo: number('longestCombo'),
      selectedBat: number('selectedBat'),
      selectedBall: number('selectedBall'),
      selectedStadium: number('selectedStadium'),
      unlockedBats: numbers('unlockedBats'),
      unlockedBalls: numbers('unlockedBalls'),
      unlockedStadiums: numbers('unlockedStadiums'),
      sound: data['sound'] as bool? ?? true,
      haptics: data['haptics'] as bool? ?? true,
      lastRewardDay: data['lastRewardDay'] as String? ?? '',
      loginStreak: number('loginStreak'),
    );
  }
}

final class PlayerStore extends ChangeNotifier {
  PlayerStore._(this.preferences, this.data);
  static const String key = 'crick_player_v1';
  final SharedPreferences preferences;
  PlayerData data;

  static Future<PlayerStore> create() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? stored = preferences.getString(key);
    PlayerData data = const PlayerData();
    if (stored != null) {
      try { data = PlayerData.decode(stored); } on Object { data = const PlayerData(); }
    }
    return PlayerStore._(preferences, data);
  }

  Future<void> update(PlayerData next) async {
    data = next;
    notifyListeners();
    await preferences.setString(key, data.encode());
  }

  Future<int> claimReward() async {
    final DateTime now = DateTime.now().toUtc();
    final String today = now.toIso8601String().substring(0, 10);
    if (data.lastRewardDay == today) return 0;
    final String yesterday = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final int streak = data.lastRewardDay == yesterday ? data.loginStreak + 1 : 1;
    final int reward = 50 + (streak - 1).clamp(0, 6) * 10;
    await update(data.copyWith(coins: data.coins + reward, lastRewardDay: today, loginStreak: streak));
    return reward;
  }
}

final class InningsResult {
  const InningsResult(this.score, this.balls, this.fours, this.sixes, this.perfects, this.hits, this.combo);
  final int score, balls, fours, sixes, perfects, hits, combo;
}

final class CrickGame extends FlameGame {
  CrickGame({required this.onFinished});
  final ValueChanged<InningsResult> onFinished;
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> balls = ValueNotifier<int>(0);
  final ValueNotifier<String> feedback = ValueNotifier<String>('WATCH THE BALL');
  final math.Random random = math.Random();
  late final Delivery delivery;
  bool resolved = false;
  int fours = 0, sixes = 0, perfects = 0, hits = 0, combo = 0, longestCombo = 0;

  @override
  Color backgroundColor() => const Color(0xFF10261B);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(Field(size: size));
    delivery = Delivery(size: size, onMiss: miss);
    add(delivery);
  }

  void swing() {
    if (resolved || balls.value >= 12) return;
    resolved = true;
    final double difference = (delivery.progress - 0.84).abs();
    int runs = 0;
    if (difference <= 0.045) { runs = 6; perfects++; sixes++; feedback.value = 'PERFECT  +6'; }
    else if (difference <= 0.105) { runs = 4; fours++; feedback.value = 'GREAT  +4'; }
    else if (difference <= 0.19) { runs = 2 + random.nextInt(2); feedback.value = 'GOOD  +$runs'; }
    else if (difference <= 0.27) { runs = 1; feedback.value = delivery.progress < 0.84 ? 'EARLY  +1' : 'LATE  +1'; }
    else { feedback.value = delivery.progress < 0.84 ? 'TOO EARLY' : 'TOO LATE'; }
    balls.value++;
    if (runs > 0) { score.value += runs; hits++; combo++; longestCombo = math.max(longestCombo, combo); } else { combo = 0; }
    delivery.hit(runs);
    Future<void>.delayed(const Duration(milliseconds: 720), next);
  }

  void miss() {
    if (resolved) return;
    resolved = true;
    balls.value++;
    combo = 0;
    feedback.value = 'BEATEN';
    Future<void>.delayed(const Duration(milliseconds: 650), next);
  }

  void next() {
    if (balls.value >= 12) {
      pauseEngine();
      onFinished(InningsResult(score.value, balls.value, fours, sixes, perfects, hits, longestCombo));
      return;
    }
    resolved = false;
    feedback.value = 'WATCH THE BALL';
    delivery.reset(0.72 + random.nextDouble() * 0.5);
  }
}

final class Field extends PositionComponent {
  Field({required super.size}) : super(priority: -10);
  final Paint grass = Paint()..color = const Color(0xFF1B5D38);
  final Paint stripe = Paint()..color = const Color(0xFF236B43);
  final Paint pitch = Paint()..color = const Color(0xFFC6A567);
  final Paint chalk = Paint()..color = const Color(0xFFF0E8D1);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), grass);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: size.x * 0.92, height: size.y * 0.86), stripe);
    final Rect strip = Rect.fromCenter(center: Offset(size.x / 2, size.y * 0.55), width: math.min(130, size.x * 0.18), height: size.y * 0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(strip, const Radius.circular(5)), pitch);
    canvas.drawRect(Rect.fromLTWH(strip.left - 18, strip.bottom - 62, strip.width + 36, 3), chalk);
    for (int i = -1; i <= 1; i++) { canvas.drawRect(Rect.fromLTWH(size.x / 2 + i * 11 - 2, strip.bottom - 55, 4, 42), chalk); }
  }
}

final class Delivery extends PositionComponent {
  Delivery({required super.size, required this.onMiss});
  final VoidCallback onMiss;
  double duration = 0.95, elapsed = 0;
  bool active = true;
  int hitRuns = -1;
  final Paint ball = Paint()..color = const Color(0xFFC63E34);
  final Paint seam = Paint()..color = const Color(0xFFF2DCC4)..strokeWidth = 2;
  final Paint bat = Paint()..color = const Color(0xFFE1C17D);
  double get progress => (elapsed / duration).clamp(0, 1);
  void reset(double value) { duration = value; elapsed = 0; active = true; hitRuns = -1; }
  void hit(int runs) { active = false; hitRuns = runs; }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;
    elapsed += dt;
    if (elapsed >= duration) { active = false; onMiss(); }
  }

  @override
  void render(Canvas canvas) {
    final double p = progress * progress;
    Offset center = Offset.lerp(Offset(size.x / 2, size.y * 0.18), Offset(size.x / 2, size.y * 0.83), p)!;
    final double radius = 7 + p * 13;
    if (!active && hitRuns > 0) center = Offset(center.dx + size.x * 0.28, center.dy - size.y * 0.18);
    canvas.drawCircle(center, radius, ball);
    canvas.drawLine(Offset(center.dx - radius * 0.35, center.dy - radius * 0.75), Offset(center.dx + radius * 0.35, center.dy + radius * 0.75), seam);
    canvas.save();
    canvas.translate(size.x / 2 + 38, size.y * 0.82);
    canvas.rotate(active ? -0.35 : -1.05);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -78, 14, 86), const Radius.circular(4)), bat);
    canvas.restore();
  }
}

class CrickApp extends StatelessWidget {
  const CrickApp({required this.store, super.key});
  final PlayerStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B8A57), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF10261B), useMaterial3: true),
    home: Home(store: store),
  );
}

class Home extends StatefulWidget {
  const Home({required this.store, super.key});
  final PlayerStore store;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() { super.initState(); unawaited(reward()); }
  Future<void> reward() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final int amount = await widget.store.claimReward();
    if (mounted && amount > 0) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Daily reward: +$amount coins')));
  }
  void open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (_, __) {
      final PlayerData d = widget.store.data;
      return Scaffold(body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(children: <Widget>[
          Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            const Text('●  CRICK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3)),
            const Spacer(),
            Text('Read the ball.\nOwn the moment.', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, height: 0.95)),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: () => open(GamePage(store: widget.store)), icon: const Icon(Icons.sports_cricket), label: const Text('PLAY 12 BALLS'), style: FilledButton.styleFrom(minimumSize: const Size(220, 58), backgroundColor: const Color(0xFFC63E34))),
            const Spacer(),
            Text('${d.coins} COINS  •  BEST ${d.highScore}  •  STREAK ${d.loginStreak}'),
          ])),
          const SizedBox(width: 38),
          Expanded(flex: 4, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Menu('Locker', 'Cosmetic unlocks', Icons.storefront, () => open(Locker(store: widget.store))),
            Menu('Career', 'Stats and achievements', Icons.bar_chart, () => open(Career(store: widget.store))),
            Menu('Settings', 'Sound and haptics', Icons.tune, () => open(Settings(store: widget.store))),
          ])),
        ]),
      )));
    },
  );
}

class Menu extends StatelessWidget {
  const Menu(this.title, this.subtitle, this.icon, this.tap, {super.key});
  final String title, subtitle;
  final IconData icon;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: ListTile(onTap: tap, minTileHeight: 72, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0x445FA87B))), tileColor: const Color(0xFF173426), leading: Icon(icon, color: const Color(0xFFE5C784)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right)));
}

class GamePage extends StatefulWidget {
  const GamePage({required this.store, super.key});
  final PlayerStore store;
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final CrickGame game = CrickGame(onFinished: finish);
  bool done = false;
  Future<void> finish(InningsResult r) async {
    if (done) return;
    done = true;
    final PlayerData d = widget.store.data;
    final int reward = r.score + r.perfects * 2;
    await widget.store.update(d.copyWith(coins: d.coins + reward, games: d.games + 1, highScore: math.max(d.highScore, r.score), totalScore: d.totalScore + r.score, fours: d.fours + r.fours, sixes: d.sixes + r.sixes, perfects: d.perfects + r.perfects, shots: d.shots + r.balls, hits: d.hits + r.hits, longestCombo: math.max(d.longestCombo, r.combo)));
    if (!mounted) return;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext dialog) => AlertDialog(title: Text('${r.score} RUNS'), content: Text('${r.sixes} sixes  •  ${r.fours} fours\n${r.perfects} perfects  •  +$reward coins'), actions: <Widget>[FilledButton(onPressed: () { Navigator.of(dialog).pop(); Navigator.of(context).pop(); }, child: const Text('DONE'))]));
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Stack(fit: StackFit.expand, children: <Widget>[
    GameWidget<CrickGame>(game: game),
    Positioned(top: 18, left: 18, child: IconButton.filledTonal(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close))),
    Positioned(top: 18, left: 82, child: ValueListenableBuilder<int>(valueListenable: game.score, builder: (_, int v, __) => Hud('$v RUNS'))),
    Positioned(top: 18, right: 18, child: ValueListenableBuilder<int>(valueListenable: game.balls, builder: (_, int v, __) => Hud('$v / 12 BALLS'))),
    Positioned(bottom: 100, left: 0, right: 0, child: ValueListenableBuilder<String>(valueListenable: game.feedback, builder: (_, String v, __) => Text(v, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)))),
    Positioned(bottom: 20, left: 0, right: 0, child: Center(child: FilledButton(onPressed: game.swing, style: FilledButton.styleFrom(minimumSize: const Size(210, 66), backgroundColor: const Color(0xFFC63E34)), child: const Text('SWING', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 2))))),
  ]));
}

class Hud extends StatelessWidget {
  const Hud(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: const Color(0xE6173224), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x556DB58A))), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900))));
}

class Locker extends StatelessWidget {
  const Locker({required this.store, super.key});
  final PlayerStore store;
  Future<void> buy(BuildContext context, String type, int index) async {
    final PlayerData d = store.data;
    final Set<int> owned = type == 'Bat' ? d.unlockedBats : type == 'Ball' ? d.unlockedBalls : d.unlockedStadiums;
    final int cost = index * (type == 'Stadium' ? 300 : type == 'Ball' ? 160 : 200);
    if (!owned.contains(index) && d.coins < cost) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins'))); return; }
    final Set<int> next = <int>{...owned, index};
    await store.update(type == 'Bat' ? d.copyWith(coins: owned.contains(index) ? d.coins : d.coins - cost, unlockedBats: next, selectedBat: index) : type == 'Ball' ? d.copyWith(coins: owned.contains(index) ? d.coins : d.coins - cost, unlockedBalls: next, selectedBall: index) : d.copyWith(coins: owned.contains(index) ? d.coins : d.coins - cost, unlockedStadiums: next, selectedStadium: index));
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (_, __) {
    final PlayerData d = store.data;
    return Scaffold(appBar: AppBar(title: Text('LOCKER  •  ${d.coins} COINS')), body: ListView(padding: const EdgeInsets.all(24), children: <Widget>[
      Items('Bat', const <String>['Classic Willow', 'Emerald Edge', 'Carbon Night'], d.selectedBat, d.unlockedBats, (int i) => buy(context, 'Bat', i)),
      Items('Ball', const <String>['Match Red', 'Pearl White', 'Midnight Gold'], d.selectedBall, d.unlockedBalls, (int i) => buy(context, 'Ball', i)),
      Items('Stadium', const <String>['Heritage Oval', 'Emerald Arena', 'Night Fortress'], d.selectedStadium, d.unlockedStadiums, (int i) => buy(context, 'Stadium', i)),
    ]));
  });
}

class Items extends StatelessWidget {
  const Items(this.type, this.names, this.selected, this.owned, this.tap, {super.key});
  final String type;
  final List<String> names;
  final int selected;
  final Set<int> owned;
  final ValueChanged<int> tap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
    Text('$type collection', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
    const SizedBox(height: 12),
    Wrap(spacing: 12, children: List<Widget>.generate(names.length, (int i) {
      final int cost = i * (type == 'Stadium' ? 300 : type == 'Ball' ? 160 : 200);
      return ActionChip(onPressed: () => tap(i), label: Text(selected == i ? '${names[i]}  •  EQUIPPED' : owned.contains(i) ? names[i] : '${names[i]}  •  $cost'));
    })),
  ]));
}

class Career extends StatelessWidget {
  const Career({required this.store, super.key});
  final PlayerStore store;
  @override
  Widget build(BuildContext context) {
    final PlayerData d = store.data;
    final List<(String, String)> stats = <(String, String)>[('Games played','${d.games}'),('Highest score','${d.highScore}'),('Average score',d.averageScore.toStringAsFixed(1)),('Sixes','${d.sixes}'),('Fours','${d.fours}'),('Perfect hits','${d.perfects}'),('Accuracy','${(d.accuracy * 100).toStringAsFixed(1)}%'),('Longest combo','${d.longestCombo}')];
    return Scaffold(appBar: AppBar(title: const Text('CAREER')), body: ListView.separated(padding: const EdgeInsets.all(24), itemCount: stats.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, int i) => ListTile(title: Text(stats[i].$1), trailing: Text(stats[i].$2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))));
  }
}

class Settings extends StatelessWidget {
  const Settings({required this.store, super.key});
  final PlayerStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (_, __) {
    final PlayerData d = store.data;
    return Scaffold(appBar: AppBar(title: const Text('SETTINGS')), body: ListView(padding: const EdgeInsets.all(24), children: <Widget>[
      SwitchListTile(title: const Text('Sound effects'), value: d.sound, onChanged: (bool v) => store.update(d.copyWith(sound: v))),
      SwitchListTile(title: const Text('Haptics'), value: d.haptics, onChanged: (bool v) => store.update(d.copyWith(haptics: v))),
      const ListTile(title: Text('Fair play economy'), subtitle: Text('Every unlock is cosmetic. No pay-to-win.')),
      const ListTile(title: Text('Cloud services'), subtitle: Text('Firebase config hub is ready for real values later.')),
    ]));
  });
}
