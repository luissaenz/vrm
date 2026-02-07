import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../data/onboarding_repository.dart';
import '../data/user_profile.dart';
import 'steps/welcome_step.dart';
import 'steps/identity_step.dart';
import 'steps/config_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  UserIdentity _selectedIdentity = UserIdentity.none;
  final OnboardingRepository _repository = OnboardingRepository();

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() async {
    await _repository.saveProfile(_selectedIdentity);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          WelcomeStep(onNext: _nextPage),
          IdentityStep(
            onSelected: (identity) {
              setState(() => _selectedIdentity = identity);
              _nextPage();
            },
          ),
          ConfigStep(
            identity: _selectedIdentity,
            onFinish: _nextPage,
            onBack: _previousPage,
          ),
        ],
      ),
    );
  }
}
