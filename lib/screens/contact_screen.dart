import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../widgets/logo_widget.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool _isInitialized = false;
  bool _isBusinessHours = false;
  String _currentTime = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeTimezone();
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    _checkBusinessHours();
    // Update every minute
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        _checkBusinessHours();
      }
    });
  }

  void _checkBusinessHours() {
    try {
      // Get UK timezone (handles BST/GMT automatically)
      final ukLocation = tz.getLocation('Europe/London');
      final now = tz.TZDateTime.now(ukLocation);
      
      final hour = now.hour;
      final minute = now.minute;
      final isWeekday = now.weekday >= 1 && now.weekday <= 5; // Monday to Friday
      
      // Business hours: 9:00 AM to 5:00 PM (17:00), Monday to Friday
      final isOpen = isWeekday && hour >= 9 && hour < 17;
      
      // Format time
      final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      final dayName = _getDayName(now.weekday);
      
      setState(() {
        _isBusinessHours = isOpen;
        _currentTime = '$dayName, $timeString (UK Time)';
        
        if (isOpen) {
          _statusMessage = 'We\'re open! Call us now.';
        } else {
          if (!isWeekday) {
            _statusMessage = 'We\'re currently closed (weekend).\nPlease email us at sales@matrixtsl.com';
          } else if (hour < 9) {
            _statusMessage = 'We\'re currently closed.\nOpening hours: Monday-Friday, 9:00 AM - 5:00 PM (UK Time)\nPlease email us at sales@matrixtsl.com';
          } else {
            _statusMessage = 'We\'re currently closed.\nOpening hours: Monday-Friday, 9:00 AM - 5:00 PM (UK Time)\nPlease email us at sales@matrixtsl.com';
          }
        }
        _isInitialized = true;
      });
    } catch (e) {
      // Fallback if timezone fails
      setState(() {
        _isBusinessHours = true; // Default to open if we can't determine
        _currentTime = 'Unable to determine UK time';
        _statusMessage = 'Call us now';
        _isInitialized = true;
      });
    }
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  Future<void> _callNow() async {
    const phoneNumber = '+441422252380'; // Remove spaces and parentheses
    final uri = Uri.parse('tel:$phoneNumber');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final uri = Uri.parse('mailto:sales@matrixtsl.com?subject=Inquiry');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                'Contact Us',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child:                   LogoWidget(
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Current Time Display
                if (_isInitialized)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: purple.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: purple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentTime,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Status Message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isBusinessHours 
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isBusinessHours 
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.orange.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isBusinessHours ? Icons.check_circle_outline : Icons.info_outline,
                        color: _isBusinessHours ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Call Now Button
                FilledButton.icon(
                  onPressed: _isBusinessHours && _isInitialized ? _callNow : null,
                  icon: const Icon(Icons.phone, size: 24),
                  label: const Text(
                    'Call Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Phone Number Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: purple, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '+44 (0) 1422 252 380',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Email Button
                OutlinedButton.icon(
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.email_outlined, size: 24),
                  label: const Text(
                    'Email Us',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    side: BorderSide(color: purple, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: purple, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'sales@matrixtsl.com',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Opening Hours Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: purple.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, color: purple, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Opening Hours',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildHoursRow('Monday - Friday', '9:00 AM - 5:00 PM'),
                      _buildHoursRow('Saturday - Sunday', 'Closed'),
                      const SizedBox(height: 12),
                      Text(
                        'All times are in UK time (GMT/BST)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

