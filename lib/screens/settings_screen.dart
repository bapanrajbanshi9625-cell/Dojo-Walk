// File location:
// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  // ============================================================
  // APP SETTINGS
  // ============================================================

  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool locationEnabled = true;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        toolbarHeight: 52,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        titleSpacing: 0,

        title: const Row(
          children: [
            Icon(
              Icons.settings_outlined,
              size: 21,
            ),
            SizedBox(
              width: 7,
            ),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            15,
            16,
            15,
            30,
          ),
          children: [

            // ==================================================
            // NOTIFICATIONS
            // ==================================================

            const _SectionTitle(
              title: 'NOTIFICATIONS',
            ),

            const SizedBox(
              height: 10,
            ),

            _SettingsCard(
              children: [
                _SwitchTile(
                  icon:
                      Icons.notifications_none_rounded,
                  title:
                      'Notifications',
                  subtitle:
                      'Receive Dojo Walk notifications',
                  value:
                      notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled =
                          value;
                    });
                  },
                ),

                const Divider(
                  height: 1,
                ),

                _SwitchTile(
                  icon:
                      Icons.volume_up_outlined,
                  title:
                      'Sound',
                  subtitle:
                      'Play sound for notifications',
                  value:
                      soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      soundEnabled =
                          value;
                    });
                  },
                ),

                const Divider(
                  height: 1,
                ),

                _SwitchTile(
                  icon:
                      Icons.vibration_outlined,
                  title:
                      'Vibration',
                  subtitle:
                      'Vibrate for important alerts',
                  value:
                      vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      vibrationEnabled =
                          value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // LOCATION
            // ==================================================

            const _SectionTitle(
              title: 'LOCATION',
            ),

            const SizedBox(
              height: 10,
            ),

            _SettingsCard(
              children: [
                _SwitchTile(
                  icon:
                      Icons.location_on_outlined,
                  title:
                      'Location Services',
                  subtitle:
                      'Allow Dojo Walk to use your location',
                  value:
                      locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      locationEnabled =
                          value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // APP PREFERENCES
            // ==================================================

            const _SectionTitle(
              title: 'APP PREFERENCES',
            ),

            const SizedBox(
              height: 10,
            ),

            _SettingsCard(
              children: [

                _SettingsTile(
                  icon:
                      Icons.language_outlined,
                  title:
                      'Language',
                  subtitle:
                      'English',
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),

                const Divider(
                  height: 1,
                ),

                _SettingsTile(
                  icon:
                      Icons.palette_outlined,
                  title:
                      'Appearance',
                  subtitle:
                      'System default',
                  onTap: () {
                    _showAppearanceDialog();
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // PRIVACY & SECURITY
            // ==================================================

            const _SectionTitle(
              title: 'PRIVACY & SECURITY',
            ),

            const SizedBox(
              height: 10,
            ),

            _SettingsCard(
              children: [

                _SettingsTile(
                  icon:
                      Icons.lock_outline_rounded,
                  title:
                      'Privacy',
                  subtitle:
                      'Manage your privacy preferences',
                  onTap: () {
                    _showComingSoon(
                      'Privacy settings',
                    );
                  },
                ),

                const Divider(
                  height: 1,
                ),

                _SettingsTile(
                  icon:
                      Icons.security_outlined,
                  title:
                      'Security',
                  subtitle:
                      'Account security options',
                  onTap: () {
                    _showComingSoon(
                      'Security settings',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // ABOUT APP
            // ==================================================

            const _SectionTitle(
              title: 'ABOUT APP',
            ),

            const SizedBox(
              height: 10,
            ),

            _SettingsCard(
              children: [

                _SettingsTile(
                  icon:
                      Icons.info_outline_rounded,
                  title:
                      'App Version',
                  subtitle:
                      'Version 1.0.0',
                  showArrow:
                      false,
                ),

                const Divider(
                  height: 1,
                ),

                _SettingsTile(
                  icon:
                      Icons.description_outlined,
                  title:
                      'Terms & Conditions',
                  subtitle:
                      'View Dojo Walk terms',
                  onTap: () {
                    _showComingSoon(
                      'Terms & Conditions',
                    );
                  },
                ),

                const Divider(
                  height: 1,
                ),

                _SettingsTile(
                  icon:
                      Icons.privacy_tip_outlined,
                  title:
                      'Privacy Policy',
                  subtitle:
                      'View our privacy policy',
                  onTap: () {
                    _showComingSoon(
                      'Privacy Policy',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // FOOTER
            // ==================================================

            const Center(
              child: Text(
                'Dojo Walk',
                style: TextStyle(
                  color:
                      AppColors.navy,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color:
                      AppColors.slate,
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Language',
            style: TextStyle(
              color:
                  AppColors.navy,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            'English is currently selected.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color:
                      AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // APPEARANCE
  // ============================================================

  void _showAppearanceDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Appearance',
            style: TextStyle(
              color:
                  AppColors.navy,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            'Dojo Walk currently follows the system appearance.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color:
                      AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(
    String title,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$title will be available soon.',
        ),
      ),
    );
  }
}

// ==================================================================
// SECTION TITLE
// ==================================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          height: 19,
          width: 4,
          decoration: BoxDecoration(
            color:
                AppColors.primary,
            borderRadius:
                BorderRadius.circular(
              5,
            ),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Text(
          title,
          style: const TextStyle(
            color:
                AppColors.navy,
            fontSize: 13,
            fontWeight:
                FontWeight.w900,
            letterSpacing:
                0.4,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// SETTINGS CARD
// ==================================================================

class _SettingsCard
    extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius:
                10,
            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child:
          Column(
        children:
            children,
      ),
    );
  }
}

// ==================================================================
// SWITCH TILE
// ==================================================================

class _SwitchTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>
      onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      child:
          Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFFFF1E8,
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        AppColors.navy,
                    fontSize:
                        14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        AppColors.slate,
                    fontSize:
                        11,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value:
                value,
            activeThumbColor:
                AppColors.primary,
            onChanged:
                onChanged,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SETTINGS TILE
// ==================================================================

class _SettingsTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback?
      onTap;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap:
          onTap,
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        child:
            Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFFF1E8,
                ),
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
              child:
                  Icon(
                icon,
                color:
                    AppColors.primary,
                size: 20,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      color:
                          AppColors.navy,
                      fontSize:
                          14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      color:
                          AppColors.slate,
                      fontSize:
                          11,
                    ),
                  ),
                ],
              ),
            ),

            if (showArrow)
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    AppColors.slate,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
