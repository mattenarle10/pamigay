import 'package:flutter/material.dart';
import 'package:pamigay/screens/common/auth/login_screen.dart';
import 'package:pamigay/screens/common/auth/multi_step_register_screen.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/screens/common/info_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PamigayColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              // Pamigay Title
             
              const SizedBox(height: 10),
              // Logo
              Image.asset(
                'lib/img/logo-white.png',
                height: 180,
              ),
              const SizedBox(height: 10),
               const Text(
                'Pamigay',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              // App description
              Text(
                'FOOD FOR GOOD',
                style: PamigayTextStyles.heading.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
           
              const Spacer(flex: 2),
              // Login button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Register button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MultiStepRegisterScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white, width: 2.5),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InfoScreen(),
                    ),
                  );
                },
                child: const Text(
                  'More About Pamigay',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
