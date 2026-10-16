import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const NightmareRunApp());

class NightmareRunApp extends StatelessWidget {
  const NightmareRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIGHTMARE RUN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05050B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF3158),
          secondary: Color(0xFF9C4DFF),
        ),
      ),
      home: const RunnerScreen(),
    );
  }
}

enum RunState { menu, playing, gameOver }

class RunnerScreen extends StatefulWidget {
  const RunnerScreen({super.key});

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  RunState _state = RunState.menu;
  int _lane = 1;
  int _score = 0;
  int _coins = 0;
  int _best = 0;
  double _distance = 0;
  double _speed = 0.32;
  double _jump = 0;
  double _slide = 0;
  double _spawnTimer = 0;
  double _coinTimer = 0;
  double _lastTime = 0;
  final List<_Obstacle> _obstacles = [];
  final List<_Coin> _coinItems = [];
  final math.Random _random = math.Random();
  Offset? _touchStart;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
    _ticker.repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = _lastTime == 0 ? 0.016 : (now - _lastTime).clamp(0.0, 0.04);
    _lastTime = now;
    if (_state != RunState.playing) return;

    setState(() {
      _distance += dt * _speed;
      _score += (dt * 18).round();
      _speed = math.min(0.72, _speed + dt * 0.002);
      _jump = math.max(0.0, _jump - dt * 1.55);
      _slide = math.max(0.0, _slide - dt * 1.2);

      _spawnTimer += dt;
      if (_spawnTimer > math.max(0.65, 1.35 - _speed)) {
        _spawnTimer = 0;
        _obstacles.add(_Obstacle(
          lane: _random.nextInt(3),
          z: 1.0,
          kind: _ObstacleKind.values[_random.nextInt(_ObstacleKind.values.length)],
        ));
      }
      _coinTimer += dt;
      if (_coinTimer > 0.7) {
        _coinTimer = 0;
        final lane = _random.nextInt(3);
        for (var i = 0; i < 4; i++) {
          _coinItems.add(_Coin(lane: lane, z: 1.0 + i * 0.065));
        }
      }

      for (final obstacle in _obstacles) {
        obstacle.z -= dt * _speed;
        if (!obstacle.checked && obstacle.z < 0.115) {
          obstacle.checked = true;
          if (obstacle.lane == _lane && _jump < 0.32 &&
              !(obstacle.kind == _ObstacleKind.lowBeam && _slide > 0.1)) {
            _finishRun();
          }
        }
      }
      _obstacles.removeWhere((o) => o.z < -0.12);
      for (final coin in _coinItems) {
        coin.z -= dt * _speed;
        if (!coin.collected && coin.z < 0.13 && coin.lane == _lane) {
          coin.collected = true;
          _coins++;
          _score += 50;
        }
      }
      _coinItems.removeWhere((c) => c.z < -0.1 || c.collected);
    });
  }

  void _startRun() {
    setState(() {
      _state = RunState.playing;
      _lane = 1;
      _score = 0;
      _coins = 0;
      _distance = 0;
      _speed = 0.32;
      _jump = 0;
      _slide = 0;
      _spawnTimer = 0;
      _coinTimer = 0;
      _obstacles.clear();
      _coinItems.clear();
    });
  }

  void _finishRun() {
    _state = RunState.gameOver;
    _best = math.max(_best, _score).toInt();
  }

  void _moveLane(int delta) {
    if (_state != RunState.playing) return;
    setState(() => _lane = (_lane + delta).clamp(0, 2).toInt());
  }

  void _jumpAction() {
    if (_state != RunState.playing) return;
    if (_jump <= 0.02) setState(() => _jump = 1);
  }

  void _slideAction() {
    if (_state != RunState.playing) return;
    setState(() => _slide = 1);
  }

  void _onPanStart(DragStartDetails details) {
    _touchStart = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    final start = _touchStart;
    _touchStart = null;
    if (start == null || _state != RunState.playing) return;
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      _moveLane(velocity.dx > 0 ? 1 : -1);
    } else if (velocity.dy < -150) {
      _jumpAction();
    } else if (velocity.dy > 150) {
      _slideAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanEnd: _onPanEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _ticker,
                builder: (_, __) => CustomPaint(
                  painter: _HorrorRunnerPainter(
                    distance: _distance,
                    lane: _lane,
                    jump: _jump,
                    slide: _slide,
                    obstacles: List<_Obstacle>.of(_obstacles),
                    coins: List<_Coin>.of(_coinItems),
                    score: _score,
                  ),
                ),
              ),
              if (_state == RunState.playing) ...[
                Positioned(
                  top: 14, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _hudPill('SCORE  $_score', Icons.bolt),
                      _hudPill('✦  $_coins', Icons.circle),
                      IconButton(
                        onPressed: () => setState(() => _state = RunState.menu),
                        icon: const Icon(Icons.pause_circle_filled, size: 34),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 18, left: 18, right: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _controlButton(Icons.arrow_back, () => _moveLane(-1)),
                      _controlButton(Icons.keyboard_arrow_up, _jumpAction),
                      _controlButton(Icons.keyboard_arrow_down, _slideAction),
                      _controlButton(Icons.arrow_forward, () => _moveLane(1)),
                    ],
                  ),
                ),
              ],
              if (_state == RunState.menu)
                _overlay(
                  eyebrow: 'DON’T LOOK BACK',
                  title: 'NIGHTMARE\nRUN',
                  subtitle: 'RUN FOR YOUR LIFE',
                  buttonText: 'START RUN',
                  onPressed: _startRun,
                  footer: 'Swipe to dodge  •  Swipe up to jump  •  Swipe down to slide',
                ),
              if (_state == RunState.gameOver)
                _overlay(
                  eyebrow: 'THE DARKNESS CAUGHT YOU',
                  title: 'GAME OVER',
                  subtitle: 'SCORE  $_score     •     COINS  $_coins\nBEST  $_best',
                  buttonText: 'RUN AGAIN',
                  onPressed: _startRun,
                  footer: 'The nightmare is never over.',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudPill(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xCC080812),
          border: Border.all(color: const Color(0x88FF3158)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(text, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1,
        )),
      );

  Widget _controlButton(IconData icon, VoidCallback action) => Material(
        color: const Color(0xAA100E1C),
        shape: CircleBorder(side: BorderSide(color: Colors.white.withOpacity(.35))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: action,
          child: SizedBox(width: 52, height: 52,
            child: Icon(icon, color: Colors.white, size: 27)),
        ),
      );

  Widget _overlay({
    required String eyebrow,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required String footer,
  }) => Container(
        color: const Color(0x9903000A),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, color: Color(0xFFFF3158), size: 45),
            const SizedBox(height: 18),
            Text(eyebrow, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFF718A), letterSpacing: 3,
                fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 46, height: .98,
                fontWeight: FontWeight.w900, letterSpacing: 2,
                shadows: [Shadow(color: Color(0xFFFF1744), blurRadius: 22)])),
            const SizedBox(height: 20),
            Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, letterSpacing: 2,
                fontSize: 13, height: 1.8)),
            const SizedBox(height: 28),
            SizedBox(
              width: 220, height: 54,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3158),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  elevation: 12,
                ),
                child: Text(buttonText, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 22),
            Text(footer, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.7)),
          ],
        ),
      );
}

enum _ObstacleKind { crate, tombstone, lowBeam }

class _Obstacle {
  _Obstacle({required this.lane, required this.z, required this.kind});
  final int lane;
  double z;
  final _ObstacleKind kind;
  bool checked = false;
}

class _Coin {
  _Coin({required this.lane, required this.z});
  final int lane;
  double z;
  bool collected = false;
}

class _HorrorRunnerPainter extends CustomPainter {
  _HorrorRunnerPainter({
    required this.distance,
    required this.lane,
    required this.jump,
    required this.slide,
    required this.obstacles,
    required this.coins,
    required this.score,
  });

  final double distance;
  final int lane;
  final double jump;
  final double slide;
  final List<_Obstacle> obstacles;
  final List<_Coin> coins;
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * .28;
    final center = w / 2;

    final bg = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF03030B), Color(0xFF171024), Color(0xFF08070D)],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final moonPaint = Paint()..color = const Color(0x22D7D4FF);
    canvas.drawCircle(Offset(w * .77, h * .12), w * .105, moonPaint);
    canvas.drawCircle(Offset(w * .77, h * .12), w * .073,
      Paint()..color = const Color(0xFFB5B4D0));

    // Distant haunted skyline.
    final skyline = Paint()..color = const Color(0xFF0A0913);
    for (int i = 0; i < 12; i++) {
      final bw = w / 10;
      final bx = i * bw - 5;
      final bh = h * (.09 + ((i * 17) % 7) * .018);
      canvas.drawRect(Rect.fromLTWH(bx, horizon - bh, bw * .8, bh), skyline);
      for (int j = 0; j < 3; j++) {
        canvas.drawRect(Rect.fromLTWH(bx + 5 + j * 8, horizon - bh + 12,
          3, 5), Paint()..color = const Color(0x553F4167));
      }
    }

    final roadPath = Path()
      ..moveTo(center - w * .06, horizon)
      ..lineTo(center + w * .06, horizon)
      ..lineTo(w * 1.1, h)
      ..lineTo(-w * .1, h)
      ..close();
    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF171620));

    // Neon road edges and three lanes.
    final edge = Paint()..color = const Color(0xAAFF3158)..strokeWidth = 2;
    canvas.drawLine(Offset(center - w * .06, horizon), Offset(-w * .1, h), edge);
    canvas.drawLine(Offset(center + w * .06, horizon), Offset(w * 1.1, h), edge);

    for (int laneIndex = 1; laneIndex <= 2; laneIndex++) {
      final topX = center + (laneIndex - 1.5) * w * .04;
      final bottomX = center + (laneIndex - 1.5) * w * .33;
      final lanePaint = Paint()
        ..color = const Color(0x667F70A8)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(topX, horizon), Offset(bottomX, h), lanePaint);
    }

    // Scrolling broken road markings create forward movement.
    for (int i = 0; i < 12; i++) {
      final z = ((i / 12.0 + distance * 1.2) % 1.0);
      final y = horizon + (h - horizon) * z * z;
      final half = w * (.008 + z * .014);
      final x = center;
      final p = Paint()..color = Color.fromARGB((80 + z * 100).round(), 155, 86, 185);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y),
        width: half, height: 2 + z * 9), p);
    }

    // Fog wisps.
    for (int i = 0; i < 5; i++) {
      final y = horizon + h * (.08 + i * .09);
      canvas.drawOval(Rect.fromCenter(
        center: Offset((center + math.sin(distance * 2 + i) * w * .2), y),
        width: w * .65, height: h * .035,
      ), Paint()..color = const Color(0x0DACA4FF));
    }

    for (final coin in coins) {
      if (!coin.collected) _drawCoin(canvas, size, coin);
    }
    for (final obstacle in obstacles) {
      _drawObstacle(canvas, size, obstacle);
    }

    _drawRunner(canvas, size);

    // Red vignette at the edges.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, const Color(0x99000000)],
        stops: const [0.48, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  Offset _project(Size s, int laneIndex, double z) {
    final t = (1 - z).clamp(0.0, 1.0);
    final center = s.width / 2;
    final laneOffset = (laneIndex - 1) * s.width * (.035 + t * .22);
    final y = s.height * .28 + (s.height * .72) * t * t;
    return Offset(center + laneOffset, y);
  }

  void _drawCoin(Canvas canvas, Size s, _Coin coin) {
    final p = _project(s, coin.lane, coin.z);
    final t = (1 - coin.z).clamp(0.0, 1.0);
    final r = 3.0 + t * 13;
    canvas.drawCircle(p, r + 4, Paint()..color = const Color(0x33FFD84A));
    canvas.drawCircle(p, r, Paint()..color = const Color(0xFFFFD84A));
    canvas.drawCircle(p, r * .62, Paint()..color = const Color(0xFFFFF0A2));
    canvas.drawRect(Rect.fromCenter(center: p, width: r * .22, height: r),
      Paint()..color = const Color(0xFFFFB52E));
  }

  void _drawObstacle(Canvas canvas, Size s, _Obstacle obstacle) {
    final p = _project(s, obstacle.lane, obstacle.z);
    final t = (1 - obstacle.z).clamp(0.0, 1.0);
    final width = 14.0 + t * 68;
    final height = 18.0 + t * 72;
    final rect = Rect.fromCenter(center: Offset(p.dx, p.dy - height * .42),
      width: width, height: height);
    if (obstacle.kind == _ObstacleKind.lowBeam) {
      final beam = Rect.fromCenter(center: Offset(p.dx, p.dy - height * .5),
        width: width * 1.45, height: math.max(5, height * .18));
      canvas.drawRect(beam, Paint()..color = const Color(0xFF6B1636));
      canvas.drawRect(beam, Paint()
        ..color = const Color(0xFFFF3158)..style = PaintingStyle.stroke..strokeWidth = 2);
      return;
    }
    final color = obstacle.kind == _ObstacleKind.crate
        ? const Color(0xFF34212B) : const Color(0xFF34313D);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(width * .08)),
      Paint()..color = color);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(width * .08)),
      Paint()..color = const Color(0xAAFF3158)
        ..style = PaintingStyle.stroke..strokeWidth = 1.5);
    if (obstacle.kind == _ObstacleKind.crate) {
      final p1 = Paint()..color = const Color(0xFF7D3145)..strokeWidth = 2 + t * 3;
      canvas.drawLine(rect.topLeft, rect.bottomRight, p1);
      canvas.drawLine(rect.topRight, rect.bottomLeft, p1);
    } else {
      final eye = Paint()..color = const Color(0xFFFF254D);
      canvas.drawCircle(Offset(p.dx - width * .16, rect.top + height * .35),
        2 + t * 4, eye);
      canvas.drawCircle(Offset(p.dx + width * .16, rect.top + height * .35),
        2 + t * 4, eye);
    }
  }

  void _drawRunner(Canvas canvas, Size s) {
    final groundY = s.height * .86;
    final center = s.width / 2 + (lane - 1) * s.width * .23;
    final jumpHeight = jump * s.height * .19;
    final scale = s.width / 390;
    final bodyY = groundY - jumpHeight - slide * 12 * scale;
    final bodyW = 42 * scale;
    final bodyH = (72 - slide * 30) * scale;

    // Shadow.
    canvas.drawOval(Rect.fromCenter(
      center: Offset(center, groundY + 6 * scale),
      width: bodyW * 1.7, height: 12 * scale,
    ), Paint()..color = const Color(0x77000000));

    // Hood and torso.
    final body = Rect.fromCenter(
      center: Offset(center, bodyY - bodyH * .1),
      width: bodyW, height: bodyH,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(10 * scale)),
      Paint()..color = const Color(0xFF16121F));
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(10 * scale)),
      Paint()..color = const Color(0xFFFF3158)
        ..style = PaintingStyle.stroke..strokeWidth = 1.6 * scale);

    final headCenter = Offset(center, bodyY - bodyH * .72);
    canvas.drawCircle(headCenter, 19 * scale, Paint()..color = const Color(0xFF090910));
    final hoodPath = Path()
      ..moveTo(center - 21 * scale, headCenter.dy + 6 * scale)
      ..lineTo(center, headCenter.dy - 26 * scale)
      ..lineTo(center + 21 * scale, headCenter.dy + 6 * scale)
      ..close();
    canvas.drawPath(hoodPath, Paint()..color = const Color(0xFF24162F));
    canvas.drawOval(Rect.fromCenter(
      center: Offset(center, headCenter.dy + 4 * scale),
      width: 24 * scale, height: 12 * scale,
    ), Paint()..color = const Color(0xFF030309));
    final eyePaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center - 6 * scale, headCenter.dy + 3 * scale),
      3 * scale, eyePaint);
    canvas.drawCircle(Offset(center + 6 * scale, headCenter.dy + 3 * scale),
      3 * scale, eyePaint);

    final limbPaint = Paint()
      ..color = const Color(0xFF17121F)
      ..strokeWidth = 9 * scale
      ..strokeCap = StrokeCap.round;
    final swing = math.sin(distance * 22) * 8 * scale;
    canvas.drawLine(Offset(center - 13 * scale, bodyY - 7 * scale),
      Offset(center - 23 * scale, bodyY + 12 * scale + swing), limbPaint);
    canvas.drawLine(Offset(center + 13 * scale, bodyY - 7 * scale),
      Offset(center + 23 * scale, bodyY + 12 * scale - swing), limbPaint);
    canvas.drawLine(Offset(center - 9 * scale, bodyY + bodyH * .25),
      Offset(center - 11 * scale + swing, groundY - 3 * scale - jumpHeight), limbPaint);
    canvas.drawLine(Offset(center + 9 * scale, bodyY + bodyH * .25),
      Offset(center + 11 * scale - swing, groundY - 3 * scale - jumpHeight), limbPaint);
  }

  @override
  bool shouldRepaint(covariant _HorrorRunnerPainter oldDelegate) => true;
}