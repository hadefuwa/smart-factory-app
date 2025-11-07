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
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoWidget(width: 28, height: 28),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  purple,
                  purple.withValues(alpha: 0.7),
                  const Color(0xFFE0B0FF),
                ],
              ).createShader(bounds),
              child: const Text(
                'About Smart Factory',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
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
                  'Smart Factory',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 1.0.5',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Overview Section
                _buildSection(
                  context,
                  icon: Icons.factory_outlined,
                  title: 'Overview',
                  content: 'The Smart Factory is designed to immerse students in the cutting-edge world of manufacturing and Industry 4.0 principles.\n\nThis comprehensive system equips students with practical experience in various processes and technologies prevalent in today\'s industrial landscape.',
                  purple: purple,
                ),

                const SizedBox(height: 24),

                // Conveyor Systems Section
                _buildSection(
                  context,
                  icon: Icons.conveyor_belt,
                  title: 'Conveyor Systems',
                  content: 'Simulate real-world manufacturing scenarios with our robust conveyor systems.\n\nLearn how conveyor belts are used to transport materials efficiently in industrial settings.',
                  purple: purple,
                ),

                const SizedBox(height: 24),

                // Sensing Systems Section
                _buildSection(
                  context,
                  icon: Icons.sensors_outlined,
                  title: 'Sensing Systems',
                  content: 'Experience advanced sensing technology including optical, proximity, and colour sensors.\n\nProgram sensors to sort coloured discs based on specific attributes, mirroring modern quality control systems.',
                  purple: purple,
                ),

                const SizedBox(height: 24),

                // Pneumatic Pick and Place Section
                _buildSection(
                  context,
                  icon: Icons.precision_manufacturing_outlined,
                  title: 'Pneumatic Pick and Place Technology',
                  content: 'Utilize pneumatic actuators and vacuum grippers to automate material handling.\n\nUnderstand the role of pneumatic systems in automating assembly lines and manufacturing processes.',
                  purple: purple,
                ),

                const SizedBox(height: 24),

                // Motor Control Section
                _buildSection(
                  context,
                  icon: Icons.settings_input_component_outlined,
                  title: 'Motor Control',
                  content: 'Control and power various motors including DC Motor Drivers and Stepper Motor Drivers to drive conveyor belts and sorting gantries.\n\nLearn about motor control techniques crucial for precision and efficiency in industrial automation.',
                  purple: purple,
                ),

                const SizedBox(height: 24),

                // Skills Development Section
                _buildSection(
                  context,
                  icon: Icons.school_outlined,
                  title: 'Real World Application',
                  content: 'The Smart Factory offers students real world application and skills development by gaining hands-on experience with technologies used in modern manufacturing.',
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
                  text: 'Smart Factory Website',
                  onTap: () => _launchURL('https://www.matrixtsl.com/smartfactory/'),
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
                    '© 2025 Smart Factory. All rights reserved.',
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
