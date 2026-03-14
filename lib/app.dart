import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/core/routes.dart';
import 'package:eyeris/ui/home_screen.dart';
import 'package:eyeris/ui/read_screen.dart';
import 'package:eyeris/ui/navigate_screen.dart';
import 'package:eyeris/ui/identify_screen.dart';
import 'package:eyeris/ui/communicate_screen.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';
import 'package:eyeris/widgets/gesture_navigation.dart';
import 'package:eyeris/widgets/sos_modal.dart';

class EyerisApp extends StatelessWidget {
  const EyerisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyeris',
      debugShowCheckedModeBanner: false,
      theme: buildEyerisTheme(),
      onGenerateRoute: _onGenerateRoute,
     initialRoute: EyerisRoutes.onboarding,   // temporary test
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final page = _pageForRoute(settings.name ?? EyerisRoutes.home);
    return _NoAnimationRoute(page: page, settings: settings);
  }

  Widget _pageForRoute(String name) {
    switch (name) {
      case EyerisRoutes.home:
        return const _HomeRoute();
      case EyerisRoutes.read:
        return const _ReadRoute();
      case EyerisRoutes.navigate:
        return const _NavigateRoute();
      case EyerisRoutes.identify:
        return const _IdentifyRoute();
      case EyerisRoutes.communicate:
        return const _CommunicateRoute();
      case EyerisRoutes.onboarding:
        return const _OnboardingRoute();
      default:
        return const _HomeRoute();
    }
  }
}

class _HomeRoute extends StatelessWidget {
  const _HomeRoute();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: HomeScreen(
        onReadTap:        () => Navigator.pushNamed(context, EyerisRoutes.read),
        onNavigateTap:    () => Navigator.pushNamed(context, EyerisRoutes.navigate),
        onIdentifyTap:    () => Navigator.pushNamed(context, EyerisRoutes.identify),
        onCommunicateTap: () => Navigator.pushNamed(context, EyerisRoutes.communicate),
        onProfileTap:     () {},
        onMicTap:         () {},
      ),
    );
  }
}

class _ReadRoute extends StatelessWidget {
  const _ReadRoute();

  @override
  Widget build(BuildContext context) {
    return ReadScreen(
      onBack:             () => Navigator.pop(context),
      onPointAndReadTap:  () {},
      onScanDocumentTap:  () {},
      onReadingSpeedTap:  () {},
      onVoiceLanguageTap: () {},
      onMicTap:           () {},
    );
  }
}

class _NavigateRoute extends StatelessWidget {
  const _NavigateRoute();

  @override
  Widget build(BuildContext context) {
    return NavigateScreen(
      onBack:          () => Navigator.pop(context),
      onWalkModeTap:   () {},
      onIndoorMapTap:  () {},
      onNearestBusTap: () {},
      onMicTap:        () {},
      gestureConfig: GestureLayerConfig(
        onBack:     () => Navigator.pop(context),
        onVoice:    () {},
        screenName: 'Navigate screen',
        options:    ['Walk Mode', 'Indoor Map', 'Nearest Bus'],
      ),
    );
  }
}

class _IdentifyRoute extends StatelessWidget {
  const _IdentifyRoute();

  @override
  Widget build(BuildContext context) {
    return IdentifyScreen(
      onBack:             () => Navigator.pop(context),
      onSceneDescribeTap: () {},
      onFindPersonTap:    () {},
      onColorDetectTap:   () {},
      onMicTap:           () {},
      gestureConfig: GestureLayerConfig(
        onBack:     () => Navigator.pop(context),
        onVoice:    () {},
        screenName: 'Identify screen',
        options:    ['Scene Describe', 'Find Person', 'Color Detect'],
      ),
    );
  }
}

class _CommunicateRoute extends StatefulWidget {
  const _CommunicateRoute();

  @override
  State<_CommunicateRoute> createState() => _CommunicateRouteState();
}

class _CommunicateRouteState extends State<_CommunicateRoute> {
  bool _sosVisible = false;

  Future<void> _showSOS() async {
    if (_sosVisible) return;
    setState(() => _sosVisible = true);
    final confirmed = await showSOSModal(context);
    if (!mounted) return;
    setState(() => _sosVisible = false);
    if (confirmed == true) {
      // Phase 5: trigger SOS broadcast
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunicateScreen(
      onBack:         () => Navigator.pop(context),
      onVoiceCallTap: () {},
      onMessagesTap:  () {},
      onSOSTap:       CommunicateScreen.sosDefaultTap,
      onSOSLongPress: _showSOS,
      onMicTap:       () {},
      gestureConfig: GestureLayerConfig(
        onBack:     () => Navigator.pop(context),
        onVoice:    () {},
        screenName: 'Communicate screen',
        options:    ['Voice Call', 'Messages', 'Emergency SOS'],
      ),
    );
  }
}

class _OnboardingRoute extends StatelessWidget {
  const _OnboardingRoute();

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      onComplete: (_) {
        // Phase 5: persist profile to shared_preferences here
        Navigator.pushNamedAndRemoveUntil(
          context,
          EyerisRoutes.home,
          (route) => false,
        );
      },
    );
  }
}

class _NoAnimationRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  _NoAnimationRoute({required this.page, required RouteSettings settings})
      : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        );
}
