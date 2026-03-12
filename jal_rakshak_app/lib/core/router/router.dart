
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'go_router_refresh_stream.dart';
import '../../features/auth/login_screen.dart';
import '../../features/water_quality/water_input_screen.dart';
import '../../features/water_quality/prediction_screen.dart';
import '../../features/readings/presentation/readings_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/prediction/presentation/disease_prediction_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/about/about_screen.dart';
import '../../features/community/community_screen.dart';
import 'package:google_fonts/google_fonts.dart';

final router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoggingIn = state.uri.toString() == '/login';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && isLoggingIn) return '/home';

    return null;
  },
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
    GoRoute(
      path: '/prediction',
      pageBuilder: (context, state) {
        final result = state.extra as Map<String, dynamic>;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PredictionScreen(result: result),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    ),
    GoRoute(
      path: '/about-us',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AboutUsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final index = _calculateSelectedIndex(context, state);
        return _AnimatedShell(
          currentIndex: index,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/news',
          pageBuilder: (context, state) => const NoTransitionPage(child: NewsScreen()),
        ),
        GoRoute(
          path: '/disease-prediction',
          pageBuilder: (context, state) => const NoTransitionPage(child: DiseasePredictionScreen()),
        ),
        GoRoute(
          path: '/input',
          pageBuilder: (context, state) => const NoTransitionPage(child: WaterQualityInputScreen()),
        ),
        GoRoute(
          path: '/readings',
          pageBuilder: (context, state) => const NoTransitionPage(child: ReadingsScreen()),
        ),
        GoRoute(
          path: '/ai-assistant',
          pageBuilder: (context, state) => const NoTransitionPage(child: ChatScreen()),
        ),
        GoRoute(
          path: '/community',
          pageBuilder: (context, state) => const NoTransitionPage(child: CommunityScreen()),
        ),
      ],
    ),
  ],
);

// ─── Animated Shell (Bottom Navigation with Sliding Animation) ─────
class _AnimatedShell extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const _AnimatedShell({
    required this.currentIndex,
    required this.child,
  });

  @override
  State<_AnimatedShell> createState() => _AnimatedShellState();
}

class _AnimatedShellState extends State<_AnimatedShell> {
  int _direction = 0; // -1: Slide Left, 1: Slide Right

  @override
  void didUpdateWidget(covariant _AnimatedShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex > oldWidget.currentIndex) {
      _direction = 1; // Navigate Next -> Slide In from Right
    } else if (widget.currentIndex < oldWidget.currentIndex) {
      _direction = -1; // Navigate Prev -> Slide In from Left
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 300) return; 

          if (velocity > 0) {
            if (widget.currentIndex > 0) {
              _onItemTapped(widget.currentIndex - 1, context);
            }
          } else if (velocity < 0) {
            if (widget.currentIndex < 5) {
              _onItemTapped(widget.currentIndex + 1, context);
            }
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Determine animation based on child key (Current vs Previous)
            final isEntering = (child.key as ValueKey<int>).value == widget.currentIndex;
            
            // If entering: Slide FROM offset to 0.
            // If exiting: Slide FROM 0 to offset (Reverse animation handles 0 to Begin).
            // Wait, reverse animation goes from 1.0 -> 0.0 of the animation value.
            // Tween evaluates at that value.
            
            // Logic for Right-to-Left (Next):
            // Enter: From (1,0) to (0,0).
            // Exit: From (0,0) to (-1,0). 
            // So Interp(0.0) should be -1. Interp(1.0) should be 0.
            // Tween(begin: -1, end: 0).evaluate(reverseAnimation) -> 0 to -1? No.
            // Correct: Tween(begin: -1, end: 0).animate(animation)
            // Forward: -1 -> 0.
            // Reverse: 0 -> -1. Yes.
            
            Tween<Offset> offsetTween;
            
            if (_direction > 0) {
              // Moving Forward (Next Tab)
              // Incoming: Right (1) -> Center (0)
              // Outgoing: Center (0) -> Left (-1)
              offsetTween = isEntering 
                ? Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                : Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero);
            } else {
              // Moving Backward (Prev Tab)
              // Incoming: Left (-1) -> Center (0)
              // Outgoing: Center (0) -> Right (1)
              offsetTween = isEntering
                ? Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                : Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero);
            }

            return SlideTransition(
              position: offsetTween.animate(animation),
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(widget.currentIndex),
            child: widget.child,
          ),
        ),
      ),
      bottomNavigationBar: _AnimatedBottomNav(
        currentIndex: widget.currentIndex,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}

// ─── Animated Bottom Nav Bar ────────────────────────────────────
class _AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AnimatedBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _NavItem(icon: Icons.home_rounded, label: 'Home', isActive: currentIndex == 0, onTap: () => onTap(0))),
                  Expanded(child: _NavItem(icon: Icons.newspaper_rounded, label: 'News', isActive: currentIndex == 1, onTap: () => onTap(1))),
                  Expanded(child: _NavItem(icon: Icons.analytics_rounded, label: 'Prediction', isActive: currentIndex == 2, onTap: () => onTap(2))),
                  Expanded(child: _NavItem(icon: Icons.water_drop_rounded, label: 'Input', isActive: currentIndex == 3, onTap: () => onTap(3))),
                  Expanded(child: _NavItem(icon: Icons.list_alt_rounded, label: 'Readings', isActive: currentIndex == 4, onTap: () => onTap(4))),
                  Expanded(child: _NavItem(icon: Icons.smart_toy_rounded, label: 'AI', isActive: currentIndex == 5, onTap: () => onTap(5))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Individual Nav Item with glow animation ────────────────────
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? const Color(0xFF2DD4BF) : Colors.white54;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: SizedBox(
          // width: 64, // Removed fixed width to prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isActive ? const Color(0xFF2DD4BF).withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect for active tab
                    if (widget.isActive)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2DD4BF).withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    Icon(widget.icon, color: color, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: widget.isActive ? 11 : 10,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _calculateSelectedIndex(BuildContext context, GoRouterState state) {
  final String location = state.uri.toString();
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/news')) return 1;
  if (location.startsWith('/disease-prediction')) return 2;
  if (location.startsWith('/input')) return 3;
  if (location.startsWith('/readings')) return 4;
  if (location.startsWith('/ai-assistant')) return 5;
  if (location.startsWith('/community')) return 4; // Fallback for community
  if (location == '/' || location == '/login') return 0; 
  return 0;
}

void _onItemTapped(int index, BuildContext context) {
  switch (index) {
    case 0:
      context.go('/home');
      break;
    case 1:
      context.go('/news');
      break;
    case 2:
      context.go('/disease-prediction');
      break;
    case 3:
      context.go('/input');
      break;
    case 4:
      context.go('/readings');
      break;
    case 5:
      context.go('/ai-assistant');
      break;
  }
}
