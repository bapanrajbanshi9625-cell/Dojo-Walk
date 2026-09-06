import 'package:flutter/material.dart';

import '../core/theme/dojo_walk_design_system.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DojoWalkColors.black,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoWalkColors.background,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor: DojoWalkColors.primary,
        foregroundColor: DojoWalkColors.white,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =================================================
      // BODY
      // =================================================

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =================================================
          // HEADER
          // =================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DojoWalkColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.support_agent_outlined,
                  color: DojoWalkColors.primary,
                  size: 38,
                ),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help?',
                        style: TextStyle(
                          color: DojoWalkColors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Find help or contact Dojo Walk support.',
                        style: TextStyle(
                          color:
                              DojoWalkColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // =================================================
          // SUPPORT OPTIONS
          // =================================================

          const Text(
            'SUPPORT',
            style: TextStyle(
              color: DojoWalkColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          // CONTACT SUPPORT
          _SupportTile(
            icon: Icons.chat_bubble_outline,
            title: 'Contact Support',
            subtitle:
                'Talk to Dojo Walk support',
            onTap: () {
              _showMessage(
                context,
                'Contact Support selected.',
              );
            },
          ),

          const SizedBox(height: 10),

          // FAQ
          _SupportTile(
            icon: Icons.question_answer_outlined,
            title: 'Frequently Asked Questions',
            subtitle:
                'Find answers to common questions',
            onTap: () {
              _showMessage(
                context,
                'FAQ selected.',
              );
            },
          ),

          const SizedBox(height: 10),

          // REPORT PROBLEM
          _SupportTile(
            icon: Icons.report_problem_outlined,
            title: 'Report a Problem',
            subtitle:
                'Tell us about a problem',
            onTap: () {
              _showMessage(
                context,
                'Report a Problem selected.',
              );
            },
          ),

          const SizedBox(height: 10),

          // SEND FEEDBACK
          _SupportTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle:
                'Share your feedback with Dojo Walk',
            onTap: () {
              _showMessage(
                context,
                'Send Feedback selected.',
              );
            },
          ),

          const SizedBox(height: 28),

          // =================================================
          // FOOTER
          // =================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DojoWalkColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.pets,
                  color: DojoWalkColors.primary,
                  size: 36,
                ),

                SizedBox(height: 10),

                Text(
                  'Dojo Walk Support',
                  style: TextStyle(
                    color: DojoWalkColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'We are here to help you with your Dojo Walk experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        DojoWalkColors.textSecondary,
                    fontSize: 12,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  'Dojo Walk • Version 1.0.0',
                  style: TextStyle(
                    color:
                        DojoWalkColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =====================================================
// SUPPORT TILE
// =====================================================

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: DojoWalkColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              // ICON
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      DojoWalkColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: DojoWalkColors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DojoWalkColors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                            DojoWalkColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ARROW
              const Icon(
                Icons.chevron_right,
                color: DojoWalkColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
