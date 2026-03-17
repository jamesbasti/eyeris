import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/core/routes.dart';
import 'package:eyeris/ui/splash_screen.dart';
import 'package:eyeris/ui/home_screen.dart';
import 'package:eyeris/ui/dashboard/read_screen.dart';
import 'package:eyeris/ui/dashboard/communicate_screen.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';
import 'package:eyeris/widgets/gesture_navigation.dart';
import 'package:eyeris/ui/camera/color_detect_camera_screen.dart';
import 'package:eyeris/ui/camera/scene_describe_camera_screen.dart';
import 'package:eyeris/widgets/sos_modal.dart';
import 'package:eyeris/widgets/sos_countdown_modal.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/services/profile_notifier.dart';
import 'package:eyeris/models/voice_command.dart';
import 'package:eyeris/services/voice/voice_control_manager.dart';

class EyerisApp extends StatefulWidget {
  const EyerisApp({super.key});

  @override
  State<EyerisApp> createState() => _EyerisAppState();
}

class _EyerisAppState extends State<EyerisApp> {
  OnboardingProfile? _profile;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void _updateProfile(OnboardingProfile profile) {
    setState(() {
      _profile = profile;
    });
    
    // Update global profile notifier to notify all listeners (including VoiceService)
    profileNotifier.updateProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyeris',
      debugShowCheckedModeBanner: false,
      theme: buildEyerisTheme(),
      navigatorKey: navigatorKey,
      initialRoute: EyerisRoutes.splash,
      onGenerateRoute: (settings) => _onGenerateRoute(settings, _profile),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings, OnboardingProfile? profile) {
    final page = _pageForRoute(settings.name ?? EyerisRoutes.home, profile);
    // Use profile hash as part of route key to force rebuild when profile changes
    final routeSettings = RouteSettings(
      name: settings.name,
      arguments: settings.arguments,
    );
    return _NoAnimationRoute(page: page, settings: routeSettings);
  }

  Widget _pageForRoute(String name, OnboardingProfile? profile) {
    switch (name) {
      case EyerisRoutes.splash:
        return _SplashRoute(onProfileUpdate: _updateProfile);
      case EyerisRoutes.home:
        return _HomeRoute(profile: profile, onProfileUpdate: _updateProfile);
      case EyerisRoutes.read:
        return _ReadRoute(profile: profile);
      case EyerisRoutes.communicate:
        return const _CommunicateRoute();
      case EyerisRoutes.onboarding:
        return const _OnboardingRoute();
      case EyerisRoutes.colorDetect:
        return const _ColorDetectRoute();
      case EyerisRoutes.sceneDescribe:
        return const _SceneDescribeRoute();
      default:
        return _HomeRoute(profile: profile, onProfileUpdate: _updateProfile); // Fallback
    }
  }
}

class _HomeRoute extends StatefulWidget {
  final OnboardingProfile? profile;
  final Function(OnboardingProfile) onProfileUpdate;

  const _HomeRoute({this.profile, required this.onProfileUpdate});

  @override
  State<_HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<_HomeRoute> {
  OnboardingProfile? _currentProfile;
  final VoiceControlManager _voiceControl = VoiceControlManager.instance;
  MicBarState _micState = MicBarState.idle;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _initVoiceControl();
  }

  @override
  void didUpdateWidget(_HomeRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      setState(() {
        _currentProfile = widget.profile;
      });
    }
  }

  Future<void> _initVoiceControl() async {
    await _voiceControl.initialize();

    _voiceControl.onStateChanged = (state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case VoiceControlState.idle:
            _micState = MicBarState.idle;
            break;
          case VoiceControlState.listening:
            _micState = MicBarState.listening;
            break;
          case VoiceControlState.processing:
          case VoiceControlState.executing:
            _micState = MicBarState.processing;
            break;
        }
      });
    };

    _voiceControl.onNavigate = (target) {
      if (!mounted) return;
      switch (target) {
        case NavigationTarget.read:
          Navigator.pushNamed(context, EyerisRoutes.read);
          break;
        case NavigationTarget.colorDetect:
          Navigator.pushNamed(context, EyerisRoutes.colorDetect);
          break;
        case NavigationTarget.sceneDescribe:
          Navigator.pushNamed(context, EyerisRoutes.sceneDescribe);
          break;
        case NavigationTarget.communicate:
          Navigator.pushNamed(context, EyerisRoutes.communicate);
          break;
        case NavigationTarget.back:
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          break;
        case NavigationTarget.home:
          Navigator.pushNamedAndRemoveUntil(
            context,
            EyerisRoutes.home,
            (route) => false,
          );
          break;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: HomeScreen(
        onReadTap:        () => Navigator.pushNamed(context, EyerisRoutes.read),
        onNavigateTap:    () => Navigator.pushNamed(context, EyerisRoutes.sceneDescribe),
        onIdentifyTap:    () => Navigator.pushNamed(context, EyerisRoutes.colorDetect),
        onEmergencySOSTap: () => Navigator.pushNamed(context, EyerisRoutes.communicate),
        onProfileTap:     () {},
        onMicTap:         () {},
        profile:          _currentProfile,
        onProfileChanged: (newProfile) {
              // Update app state when profile changes
              widget.onProfileUpdate(newProfile);
            },
        onMicPressStart:  _voiceControl.startListening,
        onMicPressEnd:    _voiceControl.stopListening,
        micState:         _micState,
      ),
    );
  }
}

class _SplashRoute extends StatelessWidget {
  final Function(OnboardingProfile) onProfileUpdate;

  const _SplashRoute({required this.onProfileUpdate});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onProfileUpdate: onProfileUpdate,
    );
  }
}

class _ReadRoute extends StatelessWidget {
  final OnboardingProfile? profile;

  const _ReadRoute({this.profile});

  @override
  Widget build(BuildContext context) {
    return ReadScreen(
      onBack:             () => Navigator.pop(context),
      onPointAndReadTap:  () {},
      onScanDocumentTap:  () {},
      onReadingSpeedTap:  () {},
      onVoiceLanguageTap: () {},
      onMicTap:           () {},
      micState:           MicBarState.idle,
      profile:            profile,
    );
  }
}

class _ColorDetectRoute extends StatelessWidget {
  const _ColorDetectRoute();

  @override
  Widget build(BuildContext context) {
    return ColorDetectCameraScreen(
      onBack: () => Navigator.pop(context),
    );
  }
}

class _SceneDescribeRoute extends StatelessWidget {
  const _SceneDescribeRoute();

  @override
  Widget build(BuildContext context) {
    return SceneDescribeCameraScreen(
      onBack: () => Navigator.pop(context),
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
    
    // Step 1: Show countdown modal
    final countdownComplete = await showSOSCountdownModal(context);
    if (!mounted) return;
    
    if (countdownComplete != true) {
      // User cancelled during countdown
      setState(() => _sosVisible = false);
      return;
    }
    
    // Step 2: Show confirmation modal
    final confirmed = await showSOSModal(context);
    if (!mounted) return;
    setState(() => _sosVisible = false);
    
    if (confirmed == true) {
      // Phase 5: trigger SOS broadcast
      debugPrint('SOS: Broadcasting emergency alert to contacts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunicateScreen(
      onBack:         () => Navigator.pop(context),
      onSOSTap:       CommunicateScreen.sosDefaultTap,
      onSOSLongPress: _showSOS,
      onMicTap:       () {},
      micState:       MicBarState.idle,
      gestureConfig: GestureLayerConfig(
        onBack:     () => Navigator.pop(context),
        onVoice:    () {},
        screenName: 'Communicate screen',
        options:    ['Emergency SOS'],
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
