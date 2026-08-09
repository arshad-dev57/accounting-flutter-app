import 'package:BisonsTechs_app/core/Register/Views/register_screen.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/route_manager.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Slides with network images (Unsplash - finance/professional)
  final List<Map<String, String>> _slides = [
    {
      'image':
          'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800&q=80',
      'tag': 'PRODUCTIVITY',
      'title': 'Boost your\nbusiness growth',
      'subtitle':
          'Reconcile transactions in seconds and get back to what matters most.',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&q=80',
      'tag': 'ANALYTICS',
      'title': 'Track every\npenny, effortlessly',
      'subtitle':
          'All your accounts, expenses and income — beautifully unified.',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&q=80',
      'tag': 'INSIGHTS',
      'title': 'Smart insights,\nbetter decisions',
      'subtitle':
          'AI-powered reports that tell you where your business is heading.',
    },
  ];

  static const Color _primary = Color(0xFF014582);
  static const Color _primaryLight = Color(0xFF0A6AB5);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _primary,
      body: Stack(
        children: [
          // ── Full-bleed background image (slides) ──
          SizedBox(
            width: size.width,
            height: size.height,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return Image.network(
                  _slides[index]['image']!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(color: _primary);
                  },
                  errorBuilder: (_, __, ___) =>
                      Container(color: _primary),
                );
              },
            ),
          ),

          // ── Gradient overlay: dark top → navy bottom ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.30, 0.60, 1.0],
                colors: [
                  Color(0xCC000000),   // dark top
                  Color(0x55000000),   // mid transparent
                  Color(0xBB012E5C),   // navy coming in
                  Color(0xFF014582),   // solid navy bottom
                ],
              ),
            ),
          ),

          // ── Top: logo + dots ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / Brand
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: _primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'BisonsTechs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Dot indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 32 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom glass card ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                28,
                32,
                28,
                MediaQuery.of(context).padding.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tag / eyebrow
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Container(
                      key: ValueKey('tag_$_currentPage'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _slides[_currentPage]['tag']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _slides[_currentPage]['title']!,
                      key: ValueKey('title_$_currentPage'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _slides[_currentPage]['subtitle']!,
                      key: ValueKey('sub_$_currentPage'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Create Account button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => RegistrationScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        Get.to(() => LoginScreen());
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}