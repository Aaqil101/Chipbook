import 'package:material_ui/material_ui.dart';

import '../app_info.dart';

/// Animated light splash shown while the app starts on mobile.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _surface = Color(0xFFF4FBF8);
  static const _deepTeal = Color(0xFF004C45);
  static const _mutedTeal = Color(0xFF4D6A64);
  static const _statusTeal = Color(0xFF6B8A83);
  static const _teal = Color(0xFF00695C);

  late final AnimationController _glow;
  late final AnimationController _bar;
  bool? _animated;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animated = !MediaQuery.disableAnimationsOf(context);
    if (_animated == animated) {
      return;
    }
    _animated = animated;
    if (animated) {
      _glow.repeat(reverse: true);
      _bar.repeat();
    } else {
      _glow.value = 0.5;
      _bar.stop();
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animated = _animated ?? true;

    return Scaffold(
      backgroundColor: _surface,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 0.95,
            colors: [Colors.white, _surface, Color(0xFFE8F4EF)],
          ),
        ),
        child: SizedBox.expand(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: animated
                  ? const Duration(milliseconds: 650)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              ),
              child: Semantics(
                liveRegion: true,
                label: 'Loading ${AppInfo.name}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _mark(animated),
                    const SizedBox(height: 22),
                    const Text(
                      AppInfo.name,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _deepTeal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppInfo.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _mutedTeal,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _progress(animated),
                    const SizedBox(height: 12),
                    const Text(
                      'LOADING…',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.2,
                        color: _statusTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mark(bool animated) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final value = animated
                  ? Curves.easeInOut.transform(_glow.value)
                  : 0.5;
              final size = 138 + 22 * value;
              return Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x3300695C), Color(0x0000695C)],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              final value = animated
                  ? Curves.easeInOut.transform(_glow.value)
                  : 0.5;
              return Transform.scale(scale: 1 + 0.035 * value, child: child);
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2E004D44),
                    blurRadius: 34,
                    offset: Offset(0, 18),
                  ),
                  BoxShadow(
                    color: Color(0x1A004D44),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(bool animated) {
    return SizedBox(
      width: 176,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const barFactor = 0.42;
            final barWidth = width * barFactor;

            if (!animated) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4DB6AC), _teal, Color(0xFF4DB6AC)],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0x1F00695C)),
                ),
                AnimatedBuilder(
                  animation: _bar,
                  builder: (context, child) {
                    final left = (width - barWidth) * _bar.value;
                    return Positioned(
                      left: left,
                      top: 0,
                      bottom: 0,
                      width: barWidth,
                      child: child!,
                    );
                  },
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4DB6AC), _teal, Color(0xFF4DB6AC)],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
