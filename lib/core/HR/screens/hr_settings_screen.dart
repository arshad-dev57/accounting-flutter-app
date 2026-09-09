import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/widgets/hr_drawer.dart';
import 'package:flutter/material.dart';


class HRSettingsScreen extends StatelessWidget {
  const HRSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          Container(
            color: kPrimary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'HR Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _card('Company', [
                  _row(Icons.business_rounded, 'Company Profile', 'BisonsTechs Pvt Ltd'),
                  _row(Icons.access_time_rounded, 'Working Hours', '09:00 AM - 06:00 PM'),
                  _row(Icons.place_rounded, 'Default Office', 'Head Office'),
                ]),
                const SizedBox(height: 12),
                _card('Attendance', [
                  _row(Icons.gps_fixed_rounded, 'Geofence Radius', '200 meters'),
                  _row(Icons.timer_rounded, 'Grace Period', '15 minutes'),
                  _row(Icons.fingerprint_rounded, 'Auto Check-in', 'Enabled'),
                ]),
                const SizedBox(height: 12),
                _card('Notifications', [
                  _row(Icons.notifications_active_rounded, 'Push Alerts', 'Enabled'),
                  _row(Icons.email_rounded, 'Email Reports', 'Daily'),
                ]),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => HRNav.logout(context),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
            ),
          ),
          Text(value, style: TextStyle(fontSize: 12, color: kSubText)),
        ],
      ),
    );
  }
}
