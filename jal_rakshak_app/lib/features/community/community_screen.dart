
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Mock Data for Community Events (Matching website content)
  final List<Map<String, dynamic>> _communityEvents = [
    {
      'id': 1,
      'title': 'Online Health Webinar',
      'type': 'online',
      'platform': 'Zoom',
      'date': 'October 20, 2025',
      'time': '3:00 PM - 5:00 PM',
      'description': 'Join our health education initiatives and community events across India to learn about water safety and disease prevention.',
      'attendees': 250,
      'status': 'upcoming'
    },
    {
      'id': 2,
      'title': 'Rural Health Camp',
      'type': 'offline',
      'venue': 'Tura Community Center, Meghalaya',
      'date': 'November 5, 2025',
      'time': '9:00 AM - 3:00 PM',
      'description': 'Free health checkups and water quality testing.',
      'attendees': 85,
      'status': 'upcoming'
    },
    {
      'id': 3,
      'title': 'Water Quality Workshop',
      'type': 'online',
      'platform': 'Microsoft Teams',
      'date': 'November 15, 2025',
      'time': '11:00 AM - 1:00 PM',
      'description': 'Virtual training session on water purification.',
      'attendees': 180,
      'status': 'upcoming'
    },
    {
      'id': 4,
      'title': 'Village Health Screening',
      'type': 'offline',
      'venue': 'Kohima School Complex, Nagaland',
      'date': 'December 2, 2025',
      'time': '8:00 AM - 2:00 PM',
      'description': 'Special health camp focusing on pediatric waterborne diseases.',
      'attendees': 200,
      'status': 'upcoming'
    },
    {
      'id': 5,
      'title': 'Water Safety Training',
      'type': 'offline',
      'venue': 'Public Hall, Patna, Bihar',
      'date': 'December 15, 2025',
      'time': '10:00 AM - 1:00 PM',
      'description': 'Hands-on training for community leaders on water safety.',
      'attendees': 120,
      'status': 'upcoming'
    },
    {
      'id': 6,
      'title': 'AI for Public Health Seminar',
      'type': 'online',
      'platform': 'Google Meet',
      'date': 'January 10, 2026',
      'time': '2:00 PM - 4:00 PM',
      'description': 'Discussing the future of AI in public health.',
      'attendees': 300,
      'status': 'upcoming'
    },
  ];

  void _handleRegister(String eventTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully registered for $eventTitle!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Container(
        decoration: null,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.groups, size: 32, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Community Outreach Programs',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join our health education initiatives and community events across India to learn about water safety and disease prevention.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Events Section
              Text(
                'Upcoming Events',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              ..._communityEvents.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            event['type'] == 'online' ? Icons.videocam : Icons.location_on,
                            color: event['type'] == 'online' ? Colors.blueAccent : Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['title'],
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event['type'] == 'online' ? event['platform'] : event['venue'],
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Upcoming',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event['description'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event['date'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _handleRegister(event['title']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text('Register Now', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 24),
              // Highlights Section
              Text(
                'Program Highlights',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildHighlightCard(Icons.videocam, 'Online Programs', 'Webinars and virtual workshops'),
              const SizedBox(height: 12),
              _buildHighlightCard(Icons.groups, 'Offline Events', 'Health camps and field visits'),
              const SizedBox(height: 12),
              _buildHighlightCard(Icons.science, 'Water Testing', 'Quality assessment and purification'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCard(IconData icon, String title, String subtitle) {
    return GlassCard(
      width: double.infinity,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
