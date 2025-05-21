import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Pamigay'),
        backgroundColor: PamigayColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              color: PamigayColors.primary,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Image.asset(
                    'lib/img/logo-white.png',
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fighting Hunger, Reducing Waste',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connecting surplus food with those who need it most',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Mission Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'At Pamigay, we believe that no good food should go to waste when it could nourish someone in need. Our mission is to create a more equitable food system by connecting excess food with those who need it most.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),

                  // Impact Numbers
                  const Text(
                    'Our Impact',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImpactCard('10,000+', 'Meals Donated'),
                  _buildImpactCard('50+', 'Partner Restaurants'),
                  _buildImpactCard('25+', 'Community Organizations'),
                  const SizedBox(height: 32),

                  // How It Works
                  const Text(
                    'How It Works',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStepCard(
                    '1',
                    'Donation',
                    'Restaurants list their surplus food through our mobile app',
                  ),
                  _buildStepCard(
                    '2',
                    'Discovery',
                    'Community organizations browse available donations',
                  ),
                  _buildStepCard(
                    '3',
                    'Pickup',
                    'Organizations collect food at scheduled times',
                  ),
                  _buildStepCard(
                    '4',
                    'Distribution',
                    'Food is distributed to those in need',
                  ),
                ],
              ),
            ),

            // Contact Section
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(24),
              child: Column(
                children: const [
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Email: info@pamigay.com\nPhone: +63 123 456 7890\nLocation: Bacolod, Philippines',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard(String number, String label) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PamigayColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String step, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PamigayColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 