import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  
  String _selectedPriority = 'Medium';
  String _selectedType = 'Bug';
  File? _selectedImage;
  bool _isSubmitting = false;
  
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _issueTypes = ['Bug', 'Crash', 'Performance', 'UI Issue', 'Data Error', 'Other'];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _submitIssue() async {
    if (_titleController.text.trim().isEmpty) {
      AppSnackbar.error(kDanger, 'Error', 'Please enter issue title');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      AppSnackbar.error(kDanger, 'Error', 'Please describe the issue');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://your-api.com/api/support/report-issue'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['steps'] = _stepsController.text.trim();
      request.fields['priority'] = _selectedPriority;
      request.fields['type'] = _selectedType;
      
      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('screenshot', _selectedImage!.path));
      }
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        AppSnackbar.success(kSuccess, 'Success', 'Issue reported successfully!');
        Future.delayed(const Duration(seconds: 2), () => Get.back());
      } else {
        throw Exception('Failed to report');
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to report issue. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Report an Issue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor:  kPrimary,
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
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildIssueForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE74C3C), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Describe the issue in detail. Attach screenshots if possible. Our team will respond within 24 hours.',
              style: const TextStyle(fontSize: 13, color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          _buildLabel('Issue Type *'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE4EE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                items: _issueTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildLabel('Priority *'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE4EE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPriority,
                isExpanded: true,
                items: _priorities.map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildLabel('Issue Title *'),
          TextField(
            controller: _titleController,
            decoration: _buildInputDecoration('Brief title of the issue'),
          ),
          const SizedBox(height: 16),
          
          _buildLabel('Description *'),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _buildInputDecoration('Detailed description of what happened'),
          ),
          const SizedBox(height: 16),
          
          _buildLabel('Steps to Reproduce'),
          TextField(
            controller: _stepsController,
            maxLines: 3,
            decoration: _buildInputDecoration('Steps to reproduce the issue...'),
          ),
          const SizedBox(height: 16),
          
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitIssue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Report',
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
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}