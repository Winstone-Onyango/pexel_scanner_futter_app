import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    void cameras() async {
      final camera = await availableCameras();
      print(camera);
    }

    void navigateWithDelay() async {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CameraScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            transitionDuration: const Duration(seconds: 3),
          ),
        );
      }
    }

    cameras();
    navigateWithDelay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: SizedBox(
            height: 90,
            width: 90,
            child: Image.asset(
              'assets/images/Pexel scanner.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
