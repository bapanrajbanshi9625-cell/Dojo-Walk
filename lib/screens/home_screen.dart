// File location: lib/screens/home_screen.dart

import 'package:flutter/material.dart';

import 'custom_app_bar.dart';

import '../features/home/services/home_data_service.dart'
    as home_data;

import '../features/home/widgets/home_past_walk.dart';
import '../features/home/widgets/home_section_title.dart';
import '../features/home/widgets/home_weekly_processing.dart';
import '../features/home/widgets/home_welcome_card.dart';

import '../widgets/generate_qr_button.dart';

// =====================================================
// HOME SCREEN
// =====================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const orange = Color(0xFFF4511E);
  static const navy = Color(0xFF263746);
  static const slate = Color(0xFF475569);
  static const background = Color(0xFFEDEFF2);
  static const card = Color(0xFFF7F8FA);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// =====================================================
// HOME STATE
// =====================================================

class _HomeScreenState extends State<HomeScreen> {
  // =====================================================
  // HOME DATA SERVICE
  // =====================================================

  final home_data.HomeDataService _homeDataService =
      home_data.HomeDataService.instance;

  // =====================================================
  // DETAILS DIALOG
  // =====================================================

  void _showDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F8FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: HomeScreen.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              color: HomeScreen.slate,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: HomeScreen.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeScreen.background,

      // ===================================================
      // APP BAR
      // ===================================================

      appBar: const CustomAppBar(),

      // ===================================================
      // BODY
      // ===================================================

      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          15,
          15,
          15,
          24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =============================================
            // WELCOME
            // =============================================

            const HomeWelcomeCard(),

            // =============================================
            // SCAN QR
            // =============================================

            const SizedBox(
              height: 8,
            ),

            const GenerateQRButton(),

            // =============================================
            // WEEKLY PROCESSING
            // =============================================

            const SizedBox(
              height: 14,
            ),

            const HomeSectionTitle(
              title: 'This week processing',
            ),

            const SizedBox(
              height: 9,
            ),

            HomeWeeklyProcessing(
              onDetails: (
                title,
                content,
              ) {
                _showDialog(
                  context,
                  title,
                  content,
                );
              },
            ),

            // =============================================
            // PAST WALK
            // =============================================

            const SizedBox(
              height: 19,
            ),

            const HomeSectionTitle(
              title: 'Past Walk',
            ),

            const SizedBox(
              height: 9,
            ),

            // =============================================
            // PAST WALK STREAM
            // =============================================

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _homeDataService.pastWalksStream(
                limit: 20,
              ),

              builder: (context, snapshot) {
                // =========================================
                // ERROR
                // =========================================

                if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: HomeScreen.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4D9DF),
                      ),
                    ),
                    child: const Text(
                      'Unable to load past walks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HomeScreen.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                // =========================================
                // LOADING
                // =========================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 70,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: HomeScreen.orange,
                      ),
                    ),
                  );
                }

                // =========================================
                // DATA
                // =========================================

                final List<Map<String, dynamic>> walks =
                    snapshot.data ??
                        <Map<String, dynamic>>[];

                // =========================================
                // PAST WALK UI
                // =========================================

                return HomePastWalk(
                  walks: walks,
                  onDetails: (
                    title,
                    content,
                  ) {
                    _showDialog(
                      context,
                      title,
                      content,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
