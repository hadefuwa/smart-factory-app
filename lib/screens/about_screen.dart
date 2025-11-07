import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/logo_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoWidget(width: 28, height: 28),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  purple,
                  purple.withValues(alpha: 0.7),
                  const Color(0xFFE0B0FF),
                ],
              ).createShader(bounds),
              child: const Text(
                'About Matrix TSL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F1E),
        foregroundColor: const Color(0xFFE0B0FF),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              purple.withValues(alpha: 0.15),
              Colors.transparent,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Info Section
                Center(
                  child:                   LogoWidget(
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Matrix TSL Product Showcase',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                    const Text(
                      'Version 1.0.3',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                const SizedBox(height: 40),
                
                // Our Vision Section
                _buildSection(
                  context,
                  icon: Icons.visibility_outlined,
                  title: 'Our Vision',
                  content: 'Inspiring the next generation of engineers through practical, hands-on learning that transforms classroom theory and prepares young people for the careers of tomorrow.',
                  purple: purple,
                ),
                
                const SizedBox(height: 24),
                
                // Who are we Section
                _buildSection(
                  context,
                  icon: Icons.business_outlined,
                  title: 'Who are we?',
                  content: 'We are a global provider of hands-on engineering education training solutions. We develop, create and manufacture innovative hardware and software designed to support the teaching of multiple engineering disciplines.\n\nOur solutions enable educators to deliver practical, industry-relevant skills with proved results, to students in schools, colleges, universities, and technical training centres worldwide.',
                  purple: purple,
                ),
                
                const SizedBox(height: 24),
                
                // Our Mission Section
                _buildSection(
                  context,
                  icon: Icons.flag_outlined,
                  title: 'Our Mission',
                  content: 'At Matrix TSL, our mission is to set a new standard in engineering education by delivering robust, hands-on training systems that are safe, accessible, and built to last.\n\nWe create high-quality, functional equipment that bridges the gap between theory and practice – helping learners build real skills with confidence.\n\nBacked by in-depth research, expert support, and comprehensive documentation, our systems illuminate complex concepts while offering unmatched value – more capability, for the same investment.\n\nWe empower educators to inspire the next generation of engineers and technicians through practical tools that work, last, and teach.',
                  purple: purple,
                ),
                
                const SizedBox(height: 32),
                
                // Links Section
                const Divider(
                  color: Color(0xFF1A1A2E),
                  thickness: 1,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.web,
                  text: 'Matrix TSL Website',
                  onTap: () => _launchURL('https://www.matrixtsl.com/'),
                  purple: purple,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.code,
                  text: 'GitHub Repository',
                  onTap: () => _launchURL('https://github.com/hadefuwa/matrix-android-app'),
                  purple: purple,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.email,
                  text: 'Contact Support',
                  onTap: () => _launchURL('mailto:support@matrixtsl.com'),
                  purple: purple,
                ),
                
                const SizedBox(height: 32),
                
                // Footer
                Center(
                  child: Text(
                    '© 2025 Matrix TSL. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color purple,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required Color purple,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: purple.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: purple, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: purple.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
