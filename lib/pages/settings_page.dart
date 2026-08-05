import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notification_service.dart';
import 'terms_page.dart';

const _accent = Color(0xFFE8A399);
const _accentDeep = Color(0xFFD8897E);
const _ink = Color(0xFF3D2F33);
const _muted = Color(0xFF7A6569);

/// Réglages de l'application (placeholder extensible).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  bool _notificationsLoading = true;
  bool _notificationsBusy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadNotificationPref());
  }

  Future<void> _loadNotificationPref() async {
    final enabled = await NotificationService.instance.notificationsEnabled;
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _notificationsLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_notificationsBusy) return;
    setState(() {
      _notificationsBusy = true;
      _notificationsEnabled = value;
    });
    await NotificationService.instance.setNotificationsEnabled(value);
    final enabled = await NotificationService.instance.notificationsEnabled;
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _notificationsBusy = false;
    });
    if (value &&
        !enabled &&
        !NotificationService.instance.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add ONESIGNAL_APP_ID to .env (see ONESIGNAL_SETUP.md).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _SettingsBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Settings',
                        style: GoogleFonts.lora(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _SettingsSection(
                    title: 'Account',
                    children: [
                      _SettingsToggleRow(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        subtitle: _notificationsLoading
                            ? 'Loading…'
                            : (_notificationsEnabled
                                ? 'Reminders for unfinished rolls'
                                : 'Off'),
                        value: _notificationsEnabled,
                        enabled: !_notificationsLoading && !_notificationsBusy,
                        onChanged: _toggleNotifications,
                      ),
                      const _SettingsRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Privacy',
                        subtitle: 'Coming soon',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'About',
                    children: [
                      const _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        label: 'App version',
                        subtitle: '1.0.0',
                      ),
                      _SettingsRow(
                        icon: Icons.description_outlined,
                        label: 'Terms & Conditions',
                        subtitle: 'Read our terms',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9F6),
            Color(0xFFF7EDE8),
            Color(0xFFF3F1F1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.25),
                    blurRadius: 80,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _muted,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _accentDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.lora(fontSize: 13, color: _muted),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: _muted.withValues(alpha: 0.7),
            ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: row,
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _accentDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.lora(fontSize: 13, color: _muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: _accentDeep,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.75),
      shape: const CircleBorder(side: BorderSide(color: Colors.white)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: _accentDeep, size: 22),
        ),
      ),
    );
  }
}
