import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utils/colors.dart';
import '../../Utils/toast_utils.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  
  String _selectedCategory = 'General Inquiry';
  bool _isSubmitting = false;
  
  final List<String> _categories = [
    'General Inquiry',
    'Technical Issue',
    'Billing Question',
    'Feature Request',
    'Account Problem',
    'Data Issue',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final Map<String, dynamic> user = json.decode(userData);
      _emailController.text = user['email'] ?? '';
    }
  }

  Future<void> _submitSupportRequest() async {
    if (_messageController.text.trim().isEmpty) {
      AppSnackbar.error(kDanger, 'Error', 'Please describe your issue');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.post(
        Uri.parse('https://your-api.com/api/support/contact'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'category': _selectedCategory,
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
          'email': _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        AppSnackbar.success(kSuccess, 'Success', 'Your request has been sent!');
        _messageController.clear();
        _subjectController.clear();
        Future.delayed(const Duration(seconds: 2), () => Get.back());
      } else {
        throw Exception('Failed to send');
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to send. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Contact Support',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1AB4F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildQuickContactCard(),
            const SizedBox(height: 20),
            _buildSupportForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1AB4F5), Color(0xFF0D8BC0)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildContactOption(Icons.email, 'Email', 'support@accpro.com'),
          _buildContactOption(Icons.phone, 'Phone', '+92 300 1234567'),
          _buildContactOption(Icons.chat, 'Live Chat', '24/7'),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () => AppSnackbar.info(label, value),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSupportForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit a Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildLabel('Issue Category *'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE4EE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('Subject'),
          TextField(
            controller: _subjectController,
            decoration: _buildInputDecoration('Brief summary'),
          ),
          const SizedBox(height: 16),
          _buildLabel('Your Email *'),
          TextField(
            controller: _emailController,
            decoration: _buildInputDecoration('your@email.com'),
          ),
          const SizedBox(height: 16),
          _buildLabel('Message *'),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: _buildInputDecoration('Describe your issue...'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitSupportRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1AB4F5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7A8FA6)),
      filled: true,
      fillColor: const Color(0xFFF5F8FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1AB4F5), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}