
import 'package:LedgerPro_app/core/Register/Views/register_screen.dart';
import 'package:LedgerPro_app/core/login/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/route_manager.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // ✅ Slides data (image + text)
  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/onboard1.png',
      'title': 'Boost productivity\non-the-go',
      'subtitle': 'Get time back with speedy bank reconciliation',
    },
    {
      'image': 'assets/onboard2.png',
      'title': 'Track your finances easily',
      'subtitle': 'Manage all your accounts in one place',
    },
    {
      'image': 'assets/onboard3.png',
      'title': 'Grow your business faster',
      'subtitle': 'Smart insights to help you succeed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _slides.length;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔵 Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1AB4F5),
                  Color(0xFF0FA3E0),
                ],
              ),
            ),
          ),

          // ⚪ Bottom White Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.58,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120),

                    // ✅ Dynamic Title
                    Text(
                      _slides[_currentPage]['title']!,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // ✅ Dynamic Subtitle
                    Text(
                      _slides[_currentPage]['subtitle']!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // 🔘 Create Account
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(RegistrationScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1AB4F5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Create an account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔘 Login
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: TextButton(
                        onPressed: () {
                          Get.to(() => LoginScreen());
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1AB4F5),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // 🔼 Top Content (Slider + Dots)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // 🔘 Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 28 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🖼 Slider
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.46,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🖼 Slide Widget
  Widget _buildSlide(int index) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            _slides[index]['image']!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}