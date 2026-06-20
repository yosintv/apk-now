import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _barCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _barProgress;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.85, curve: Curves.elasticOut),
      ),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _barProgress = Tween<double>(begin: 0.0, end: 0.9).animate(
      CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _floatY = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _textCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        _barCtrl.forward();
        _floatCtrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF050E2E),
              Color(0xFF091A4A),
              Color(0xFF0D2460),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // ── Animated logo ────────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_logoCtrl, _floatCtrl]),
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatY.value),
                  child: Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.55),
                              blurRadius: 48,
                              spreadRadius: 6,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.12),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.live_tv_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 38),

              // ── Animated text ─────────────────────────────────────────
              AnimatedBuilder(
                animation: _textCtrl,
                builder: (_, __) => Opacity(
                  opacity: _textFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Column(
                      children: [
                        const Text(
                          'YoSinTV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Text(
                            '24/7  ·  Football & Cricket',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Progress bar ──────────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_barCtrl, _textCtrl]),
                builder: (_, __) => Opacity(
                  opacity: _textFade.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 52),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            height: 3,
                            child: LinearProgressIndicator(
                              value: _barProgress.value,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.10),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.lerp(
                                  AppColors.primaryLight,
                                  const Color(0xFF7EB3FF),
                                  _barProgress.value,
                                )!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'LOADING',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
