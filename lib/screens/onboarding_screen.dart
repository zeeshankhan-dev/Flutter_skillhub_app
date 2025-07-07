import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B3B98), Color(0xFF9B59B6)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // PageView for onboarding steps
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    isLastPage = index == 2;
                  });
                },
                children: [
                  buildPage(
                    image: 'assets/images/find_experts.png',
                    title: "Find Experts",
                    description:
                    "Browse skilled professionals for your projects easily.",
                  ),
                  buildPage(
                    image: 'assets/images/post_project.png',
                    title: "Post a Project",
                    description:
                    "Post jobs and receive proposals from professionals.",
                  ),
                  buildPage(
                    image: 'assets/images/get_work_done.png',
                    title: "Get Work Done",
                    description:
                    "Approve proposals, track progress, and complete projects.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Smooth page indicator (dots)
            SmoothPageIndicator(
              controller: _controller,
              count: 3,
              effect: const WormEffect(
                activeDotColor: Colors.white,
                dotColor: Colors.white30,
                dotHeight: 10,
                dotWidth: 10,
              ),
            ),

            const SizedBox(height: 20),

            // Navigation Buttons: SKIP & NEXT/START
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      "SKIP",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Next or Start Button
                  TextButton(
                    onPressed: () {
                      if (isLastPage) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      isLastPage ? "START" : "NEXT",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Reusable onboarding page builder widget
  Widget buildPage({
    required String image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Onboarding image
          Image.asset(
            image,
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 30),

          // Title text
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 10),

          // Description text
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
