import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  double _x = 0.0;
  double _y = 0.0;

  // PARAMETER OF ANIMATION
  final _cardWidth = 300.h;
  final _maxIncline = 0.4; //maximum incline
  final _factorIncline = 0.10; // incline sensibility
  final _factorGradient = 1000.0; // color gradient sensibility
  final _factorShadow = 40.0; // elevation shadow sensibility
  final hue = 1.0; // color gradient hue
  final saturation = 0.9; // color gradient saturation

  late AnimationController _controller;
  late Animation<double> _animationX;
  late Animation<double> _animationY;
  double _prevX = 0.0;
  double _prevY = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _animationX = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
    _animationY = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    gyroscopeEventStream().listen((GyroscopeEvent event) {
      setState(() {
        _x += event.x * _factorIncline;
        _y += event.y * _factorIncline;

        //clamping incline
        _x = _x.clamp(-_maxIncline, _maxIncline);
        _y = _y.clamp(-_maxIncline, _maxIncline);

        _animationX = Tween<double>(
          begin: _prevX,
          end: _x,
        ).animate(_controller);
        _animationY = Tween<double>(
          begin: _prevY,
          end: _y,
        ).animate(_controller);

        _controller.forward(from: 0.0);

        _prevX = _x;
        _prevY = _y;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-_animationX.value)
                  ..rotateY(_animationY.value),
                alignment: FractionalOffset.center,
                child: GestureDetector(
                  // get back to init state to avoid anormal rotations
                  onTap: () => setState(() {
                    _x = 0;
                    _y = 0;
                  }),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: _cardWidth - 1,
                          // height is manually fixe -> to fix
                          height: 410.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                spreadRadius: 5,
                                blurRadius: 11,
                                offset: Offset(
                                    _y * _factorShadow, _x * _factorShadow),
                              ),
                            ],
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcATop,
                            ),
                            child: Image.asset(
                              'assets/images/carte.png',
                              width: _cardWidth,
                            ),
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return RadialGradient(
                            center: Alignment(_y, _x),
                            radius: 0.8,
                            stops: const [0.1, 0.7],
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Color.fromARGB(255, 150, 150, 150),
                            ],
                          ).createShader(bounds);
                        },
                        child: Center(
                          child: Image.asset(
                            'assets/images/carte.png',
                            width: _cardWidth,
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          final dx = _x / bounds.width;
                          final rotationX =
                              (dx * math.pi * 180 / math.pi) + 180;
                          return RadialGradient(
                            center: Alignment(_y, _x),
                            radius: 0.8.h,
                            stops: const [0.1, 0.7],
                            colors: [
                              Colors.white.withOpacity(0.3),
                              HSVColor.fromAHSV(
                                      hue,
                                      rotationX * _factorGradient % 360,
                                      saturation,
                                      1.0)
                                  .toColor(),
                            ],
                          ).createShader(bounds);
                        },
                        child: Center(
                          child: Image.asset(
                            'assets/images/over.png',
                            width: _cardWidth,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
