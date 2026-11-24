import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state/app_state_controller.dart';
import 'ui/camera/camera_overlay_screen.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive edge-to-edge system UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MobileLanguageApp());
}

class MobileLanguageApp extends StatefulWidget {
  const MobileLanguageApp({super.key});

  @override
  State<MobileLanguageApp> createState() => _MobileLanguageAppState();
}

class _MobileLanguageAppState extends State<MobileLanguageApp> {
  late final AppStateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppStateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Language App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: CameraOverlayScreen(controller: _controller),
    );
  }
}
