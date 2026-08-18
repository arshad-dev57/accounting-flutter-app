import 'dart:convert';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/support/controllers/support_ticket_controller.dart';
import 'package:BisonsTechs_app/core/support/screens/support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _priority = 'Medium';
  bool _submitting = false;
  String _userName = '';
  String _userEmail = '';
  late final SupportTicketController _controller;

  static const _supportEmail = 'support@bisonstechs.com';
  static const _supportPhone = '+92 300 0000000';

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SupportTicketController>()
        ? Get.find<SupportTicketController>()
        : Get.put(SupportTicketController());
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user') ?? prefs.getString('user_data');
      if (raw == null) return;
      final map = json.decode(raw) as Map<String, dynamic>;
      final first = map['firstName']?.toString() ?? '';
      final last = map['lastName']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _userName = '$first $last'.trim();
        _userEmail = map['email']?.toString() ??
            prefs.getString('user_email') ??
            '';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Message required',
        'Please write your question or issue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kDanger,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await _controller.createTicket(
        title: _subjectCtrl.text.trim().isEmpty
            ? 'Support request'
            : _subjectCtrl.text.trim(),
        description: _messageCtrl.text.trim(),
        category: 'General',
        priority: _priority,
      );
      if (ok && mounted) Get.back();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: uri.path.isEmpty ? uri.toString() : uri.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _supportEmail,
                  onTap: () => _launch(Uri.parse('mailto:$_supportEmail')),
                ),
                const SizedBox(height: 10),
                _infoCard(
                  icon: Icons.call_outlined,
                  label: 'Phone',
                  value: _supportPhone,
                  onTap: () => _launch(Uri.parse('tel:${_supportPhone.replaceAll(' ', '')}')),
                ),
                if (_userEmail.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoCard(
                    icon: Icons.person_outline,
                    label: 'Logged in as',
                    value: _userName.isEmpty ? _userEmail : '$_userName · $_userEmail',
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'Send a message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our team usually replies within 1 business day.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                _formCard(),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Get.to(() => const SupportTicketsScreen()),
                    child: const Text('View my tickets'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimary.withOpacity(0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.headset_mic_outlined, color: Colors.white, size: 28),
          SizedBox(height: 10),
          Text(
            'How can we help?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Reach BisonsTechs support by email, phone, or the form below.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _subjectCtrl,
            decoration: _dec('Subject'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 5,
            decoration: _dec('Message'),
          ),
          const SizedBox(height: 14),
          Text(
            'Priority',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _controller.priorities.map((p) {
              final selected = _priority == p;
              return ChoiceChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) => setState(() => _priority = p),
                selectedColor: kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1A1D2E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                backgroundColor: const Color(0xFFF5F6FA),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send message',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEFF4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEFF4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.4),
      ),
    );
  }
}
