import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/dashboard/Screens/dashbaord_screen.dart';
import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
    final List<Map<String, TextEditingController>> _phoneNumbers = [];
  final List<Map<String, TextEditingController>> _addresses = [];
  final List<TextEditingController> _notes = [];

  @override
  void initState() {
    super.initState();
    // Add one empty phone number field initially
    _addNewPhoneNumber();
    // Add one empty address field initially
    _addNewAddress();
    // Add one empty note field initially
    _addNewNote();
  }

  void _addNewPhoneNumber() {
    setState(() {
      _phoneNumbers.add({
        'number': TextEditingController(),
        'type': TextEditingController(text: 'Mobile'),
      });
    });
  }

  void _removePhoneNumber(int index) {
    setState(() {
      _phoneNumbers[index]['number']?.dispose();
      _phoneNumbers.removeAt(index);
    });
  }

  void _addNewAddress() {
    setState(() {
      _addresses.add({
        'address': TextEditingController(),
        'type': TextEditingController(text: 'Home'),
      });
    });
  }

  void _removeAddress(int index) {
    setState(() {
      _addresses[index]['address']?.dispose();
      _addresses.removeAt(index);
    });
  }

  void _addNewNote() {
    setState(() {
      _notes.add(TextEditingController());
    });
  }

  void _removeNote(int index) {
    setState(() {
      _notes[index].dispose();
      _notes.removeAt(index);
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _contactNameController.dispose();
    _accountNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    
    for (var phone in _phoneNumbers) {
      phone['number']?.dispose();
    }
    
    for (var address in _addresses) {
      address['address']?.dispose();
    }
    
    for (var note in _notes) {
      note.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon:  Icon(Icons.arrow_back, color: kText),
        onPressed: () => Navigator.pop(context),
      ),
      title:  Text(
        'Contact',
        style: TextStyle(
          color: kText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _saveContact,
          style: TextButton.styleFrom(
            foregroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child:Text(
            'Save',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  BODY
  // ════════════════════════════════════════════
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Contact Name Section
          _buildContactNameSection(),
          const SizedBox(height: 12),
          
          // Account Number Section
          _buildAccountNumberSection(),
          const SizedBox(height: 12),
          
          // Primary Person Section
          _buildPrimaryPersonSection(),
          const SizedBox(height: 12),
          
          // Email Address Section
          _buildEmailSection(),
          const SizedBox(height: 12),
          
          // Phone Numbers Section
          _buildPhoneNumbersSection(),
          const SizedBox(height: 12),
          
          // Addresses Section
          _buildAddressesSection(),
          const SizedBox(height: 12),
          
          // Notes Section
          _buildNotesSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  CONTACT NAME SECTION
  // ════════════════════════════════════════════
  Widget _buildContactNameSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'What is the contact\'s name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _contactNameController,
              decoration: InputDecoration(
                hintText: 'Enter contact name',
                hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(Icons.person_outline, color: kSubText, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  ACCOUNT NUMBER SECTION
  // ════════════════════════════════════════════
  Widget _buildAccountNumberSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'ACCOUNT NUMBER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                hintText: 'Enter an account number',
                hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(Icons.account_balance_outlined, color: kSubText, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  PRIMARY PERSON SECTION
  // ════════════════════════════════════════════
  Widget _buildPrimaryPersonSection() {
    return Container(
      color: Colors.white,
      padding:  EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'PRIMARY PERSON',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNameField(
                  label: 'First name',
                  controller: _firstNameController,
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNameField(
                  label: 'Last name',
                  controller: _lastNameController,
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: kSubText,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
              prefixIcon: Icon(icon, color: kSubText, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Email Address',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter email address',
                hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(Icons.email_outlined, color: kSubText, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumbersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'NUMBER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _phoneNumbers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildPhoneNumberTile(index);
            },
          ),
          
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addNewPhoneNumber,
            icon: Icon(Icons.add_circle_outline, color: kPrimary, size: 20),
            label: Text(
              '+ New Contact Number',
              style: TextStyle(
                fontSize: 14,
                color: kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberTile(int index) {
    return Row(
      children: [
        Container(
          width: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _phoneNumbers[index]['type']?.text ?? 'Mobile',
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: kSubText),
                items: ['Mobile', 'Home', 'Work', 'Other'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: TextStyle(fontSize: 13, color: kText),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _phoneNumbers[index]['type']?.text = value ?? 'Mobile';
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _phoneNumbers[index]['number'],
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
                prefixIcon: Icon(Icons.phone_outlined, color: kSubText, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        if (_phoneNumbers.length > 1)
          IconButton(
            icon: Icon(Icons.close, size: 18, color: kSubText),
            onPressed: () => _removePhoneNumber(index),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  ADDRESSES SECTION
  // ════════════════════════════════════════════
  Widget _buildAddressesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'ADDRESS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          
          // List of addresses
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildAddressTile(index);
            },
          ),
          
          const SizedBox(height: 8),
          
          // Add new address button
          TextButton.icon(
            onPressed: _addNewAddress,
            icon: Icon(Icons.add_circle_outline, color: kPrimary, size: 20),
            label: Text(
              '+ NEW ADDRESS',
              style: TextStyle(
                fontSize: 14,
                color: kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _addresses[index]['type']?.text ?? 'Home',
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: kSubText),
                      items: ['Home', 'Work', 'Office', 'Other'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(fontSize: 13, color: kText),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _addresses[index]['type']?.text = value ?? 'Home';
                        });
                      },
                    ),
                  ),
                ),
              ),
              if (_addresses.length > 1)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: kSubText),
                  onPressed: () => _removeAddress(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addresses[index]['address'],
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter full address',
              hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kPrimary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  NOTES SECTION
  // ════════════════════════════════════════════
  Widget _buildNotesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'NOTE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          
          // List of notes
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildNoteTile(index);
            },
          ),
          
          const SizedBox(height: 8),
          
          // Add new note button
          TextButton.icon(
            onPressed: _addNewNote,
            icon: Icon(Icons.add_circle_outline, color: kPrimary, size: 20),
            label: Text(
              '+ NOTE',
              style: TextStyle(
                fontSize: 14,
                color: kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteTile(int index) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _notes[index],
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter note',
                hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
                prefixIcon: Icon(Icons.note_outlined, color: kSubText, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        if (_notes.length > 1)
          IconButton(
            icon: Icon(Icons.close, size: 18, color: kSubText),
            onPressed: () => _removeNote(index),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  SAVE CONTACT METHOD
  // ════════════════════════════════════════════
  void _saveContact() {
    // Validate required fields
    if (_contactNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter contact name');
      return;
    }

    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter first and last name');
      return;
    }

    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('Please enter email address');
      return;
    }

    // Validate email format
    if (!_isValidEmail(_emailController.text)) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    // Check if at least one phone number is entered
    bool hasPhoneNumber = false;
    for (var phone in _phoneNumbers) {
      if (phone['number']?.text.isNotEmpty ?? false) {
        hasPhoneNumber = true;
        break;
      }
    }
    if (!hasPhoneNumber) {
      _showErrorSnackBar('Please enter at least one phone number');
      return;
    }

    // Check if at least one address is entered
    bool hasAddress = false;
    for (var address in _addresses) {
      if (address['address']?.text.isNotEmpty ?? false) {
        hasAddress = true;
        break;
      }
    }
    if (!hasAddress) {
      _showErrorSnackBar('Please enter at least one address');
      return;
    }

    // Here you would typically save the contact
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact saved successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    
    Navigator.pop(context);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}