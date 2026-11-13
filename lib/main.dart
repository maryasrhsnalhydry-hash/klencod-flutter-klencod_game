import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اصطد النجوم',
      theme: ThemeData.dark(),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const GamePage(),
    );
  }
}

class Item {
  double x;
  double y;
  final bool star;
  Item(this.x, this.y, this.star);
}

const double worldW = 360;
const double worldH = 480;
const double basketW = 60;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Random _rnd = Random();
  Duration _last = Duration.zero;
  double _spawn = 0;
  double _px = 150;
  List<Item> _items = [];
  int _score = 0;
  int _lives = 3;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {
      _items = [];
      _score = 0;
      _lives = 3;
      _over = false;
      _spawn = 0;
      _px = 150;
    });
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (_over) return;

    _spawn += dt;
    if (_spawn > 0.65) {
      _spawn = 0;
      _items.add(Item(_rnd.nextDouble() * (worldW - 24), -20,
          _rnd.nextDouble() > 0.3));
    }

    final speed = 120 + _score * 6;
    for (final i in _items) {
      i.y += speed * dt;
    }

    final kept = <Item>[];
    for (final i in _items) {
      final hit = i.y > worldH - 40 &&
          i.y < worldH - 10 &&
          i.x + 24 > _px &&
          i.x < _px + basketW;
      if (hit) {
        if (i.star) {
          _score++;
        } else {
          _lives--;
        }
        if (_lives <= 0) _over = true;
      } else if (i.y < worldH) {
        kept.add(i);
      }
    }
    _items = kept;
    setState(() {});
  }

  void _moveTo(double dx, double width) {
    final wx = dx / width * worldW - basketW / 2;
    _px = wx.clamp(0.0, worldW - basketW);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2A41),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('اصطد النجوم ⭐',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('النقاط: $_score   |   الأرواح: $_lives',
                  style: const TextStyle(fontSize: 18)),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: worldW / worldH,
                  child: LayoutBuilder(
                    builder: (context, c) => GestureDetector(
                      onPanDown: (d) => _moveTo(d.localPosition.dx, c.maxWidth),
                      onPanUpdate: (d) =>
                          _moveTo(d.localPosition.dx, c.maxWidth),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1B2D),
                          border: Border.all(
                              color: const Color(0xFFF2C14E), width: 3),
                        ),
                        child: CustomPaint(
                          painter: GamePainter(_items, _px, _over, _score),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('اسحب بإصبعك لتحريك السلة، وتجنب الصخور!'),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: _restart,
                child: const Text('ابدأ من جديد'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final List<Item> items;
  final double px;
  final bool over;
  final int score;
  GamePainter(this.items, this.px, this.over, this.score);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / worldW, size.height / worldH);

    canvas.drawRect(
      Rect.fromLTWH(px, worldH - 30, basketW, 16),
      Paint()..color = const Color(0xFFF2C14E),
    );

    for (final i in items) {
      final tp = TextPainter(
        text: TextSpan(text: i.star ? '⭐' : '🪨', style: const TextStyle(fontSize: 24)),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(i.x, i.y));
    }

    if (over) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, worldW, worldH),
        Paint()..color = const Color(0x99000000),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: 'انتهت اللعبة! نقاطك: $score',
          style: const TextStyle(fontSize: 26, color: Colors.white),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset((worldW - tp.width) / 2, worldH / 2 - tp.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}