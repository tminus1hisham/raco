import 'package:atom/config/constants.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Onboarding extends StatefulWidget {
  @override
  _OnboardingState createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int activeIndex = 0;
  final CarouselSliderController controller = CarouselSliderController();

  final List<OnboardingData> onboardingItems = [
    OnboardingData(
      image: 'assets/image_2.jpg',
      title: 'Real-Time Vehicle Tracking',
      description:
          'Monitor your fleet in real-time with GPS and OBD-II data. Stay updated on location, speed, and vehicle health directly from the app.',
    ),
    OnboardingData(
      image: 'assets/image_3.jpg',
      title: 'Smart Alerts & Notifications',
      description:
          'Receive instant alerts for overspeeding, tampering, and abnormal vehicle conditions. Stay compliant and keep your drivers safe.',
    ),
    OnboardingData(
      image: 'assets/image_1.jpg',
      title: 'Fleet & Driver Management',
      description:
          'Easily manage vehicles, assign drivers, and access trip history with secure role-based access. Streamline operations and improve efficiency.',
    ),
    OnboardingData(
      image: 'assets/image_1.jpg',
      title: 'Compliance & Reporting',
      description:
          'Generate NTSA-compliant reports, view trip summaries, and download performance insights to keep your fleet compliant and accountable.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Hero(
                tag: "logo",
                child: Image(
                  image: const AssetImage('assets/orca_logo.png'),
                  height: 140,
                  width: 140,
                ),
              ),
            ),

            // Carousel content
            Expanded(
              child: Column(
                children: [
                  // Carousel slider
                  Expanded(
                    child: CarouselSlider.builder(
                      carouselController: controller,
                      itemCount: onboardingItems.length,
                      itemBuilder: (context, index, realIndex) {
                        final item = onboardingItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              // Image container
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  child: Image.asset(
                                    item.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              const SizedBox(height: kSpace3XL),

                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: kBlack,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: kGrey,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: size.height * 0.7,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        autoPlay: false,
                        onPageChanged: (index, reason) {
                          setState(() {
                            activeIndex = index;
                          });
                        },
                      ),
                    ),
                  ),

                  AnimatedSmoothIndicator(
                    activeIndex: activeIndex,
                    count: onboardingItems.length,
                    effect: WormEffect(
                      dotWidth: 8,
                      dotHeight: 8,
                      activeDotColor: kBlue,
                      dotColor: kLightGrey,
                      spacing: 8,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomButton(
                    callBackFunction: () {
                      if (activeIndex == onboardingItems.length - 1) {
                        _handleSignIn();
                      } else {
                        // Next screen
                        controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    label: activeIndex == onboardingItems.length - 1
                        ? 'Sign in'
                        : 'Next',
                    backgroundColor: kBlue,
                    txtColor: kWhite,
                  ),

                  const SizedBox(height: 10),

                  if (activeIndex != onboardingItems.length - 1)
                    CustomBorderButton(
                      callBackFunction: () {
                        if (activeIndex == onboardingItems.length - 1) {
                          _handleSignUp();
                        } else {
                          controller.animateToPage(
                            onboardingItems.length - 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      label: 'Skip',
                      borderColor: kLightGrey,
                      txtColor: kGrey,
                    ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage('assets/logo.png'),
                        height: 40,
                        width: 40,
                      ),
                      SizedBox(width: 20),
                      Text('Powered by Atom', style: TextStyle(color: kGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignIn() {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  void _handleSignUp() {
    Navigator.pushNamed(context, AppRoutes.login);
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
