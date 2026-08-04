// lib/core/dashboard/widgets/profile_dropdown.dart

import 'package:LedgerPro_app/core/companyprofile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

const _kPageBg = Color(0xFFF5F6FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFE8EAF0);
const _kTextPrimary = Color(0xFF1A1D2E);
const _kTextSecondary = Color(0xFF8B90A7);
const _kBlue = Color(0xFF014582);
const _kBlueDark = Color(0xFF014582);
const _kRed = Color(0xFFEF4444);


class ProfileDropdown extends StatefulWidget {
  final ProfileController profileCtrl;
  final VoidCallback onLogout;
  const ProfileDropdown({
    super.key,
    required this.profileCtrl,
    required this.onLogout,
  });

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _removeOverlay();
    _animCtrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _closeDropdown() {
    _animCtrl.reverse().then((_) {
      _removeOverlay();
      if (mounted) setState(() => _isOpen = false);
    });
  }

  void _openDropdown() {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    _overlayEntry = OverlayEntry(
      builder: (_) => _DropdownOverlay(
        layerLink: _layerLink,
        fadeAnim: _fadeAnim,
        slideAnim: _slideAnim,
        profileCtrl: widget.profileCtrl,
        onLogout: widget.onLogout,
        onClose: _closeDropdown,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward();
  }

  void _toggle() => _isOpen ? _closeDropdown() : _openDropdown();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBlue, _kBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: (_isHovered || _isOpen)
                  ? [
                      BoxShadow(
                        color: _kBlue.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}


class _DropdownOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final ProfileController profileCtrl;
  final VoidCallback onLogout, onClose;
  const _DropdownOverlay({
    required this.layerLink,
    required this.fadeAnim,
    required this.slideAnim,
    required this.profileCtrl,
    required this.onLogout,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: _ProfileDropdownCard(
                  profileCtrl: profileCtrl,
                  onClose: onClose,
                  onLogout: onLogout,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _ProfileDropdownCard extends StatefulWidget {
  final ProfileController profileCtrl;
  final VoidCallback onClose, onLogout;
  const _ProfileDropdownCard({
    required this.profileCtrl,
    required this.onClose,
    required this.onLogout,
  });
  @override
  State<_ProfileDropdownCard> createState() => _ProfileDropdownCardState();
}

class _ProfileDropdownCardState extends State<_ProfileDropdownCard> {
  bool _isEditing = false;
  late final TextEditingController _orgCtrl,
      _personCtrl,
      _addressCtrl,
      _emailCtrl,
      _phoneCtrl,
      _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profileCtrl;
    _orgCtrl = TextEditingController(text: p.organizationName.value);
    _personCtrl = TextEditingController(text: p.personName.value);
    _addressCtrl = TextEditingController(text: p.address.value);
    _emailCtrl = TextEditingController(text: p.email.value);
    _phoneCtrl = TextEditingController(text: p.contactNo.value);
    _websiteCtrl = TextEditingController(text: p.websiteLink.value);
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _personCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _startEdit() {
    final p = widget.profileCtrl;
    _orgCtrl.text = p.organizationName.value;
    _personCtrl.text = p.personName.value;
    _addressCtrl.text = p.address.value;
    _emailCtrl.text = p.email.value;
    _phoneCtrl.text = p.contactNo.value;
    _websiteCtrl.text = p.websiteLink.value;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() => setState(() => _isEditing = false);

  Future<void> _saveEdit() async {
    final p = widget.profileCtrl;
    p.orgNameController.text = _orgCtrl.text;
    p.personNameController.text = _personCtrl.text;
    p.addressController.text = _addressCtrl.text;
    p.emailController.text = _emailCtrl.text;
    p.contactNoController.text = _phoneCtrl.text;
    p.websiteController.text = _websiteCtrl.text;
    if (p.validateForm()) await p.saveProfile();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      constraints: const BoxConstraints(maxHeight: 540),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _isEditing ? _buildEditBody() : _buildViewBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBlue, _kBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profileCtrl.organizationName.value.isEmpty
                        ? 'Your Organization'
                        : widget.profileCtrl.organizationName.value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.profileCtrl.personName.value.isEmpty
                        ? 'Account Owner'
                        : widget.profileCtrl.personName.value,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.72),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _isEditing ? _cancelEdit : _startEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isEditing ? 'Cancel' : 'Edit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewBody() {
    return SingleChildScrollView(
      key: const ValueKey('view'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Organization', [
            _InfoRow(
              icon: Mdi.domain,
              label: 'Name',
              value: widget.profileCtrl.organizationName.value,
            ),
            _InfoRow(
              icon: Mdi.account,
              label: 'Contact',
              value: widget.profileCtrl.personName.value,
            ),
            _InfoRow(
              icon: Mdi.map_marker,
              label: 'Address',
              value: widget.profileCtrl.address.value,
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoSection('Contact', [
            _InfoRow(
              icon: Mdi.email,
              label: 'Email',
              value: widget.profileCtrl.email.value,
            ),
            _InfoRow(
              icon: Mdi.phone,
              label: 'Phone',
              value: widget.profileCtrl.contactNo.value,
            ),
            _InfoRow(
              icon: Mdi.web,
              label: 'Web',
              value: widget.profileCtrl.websiteLink.value,
            ),
          ]),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () {
              widget.onClose();
              widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded, size: 13),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(
              foregroundColor: _kRed,
              backgroundColor: _kRed.withOpacity(0.07),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _kTextSecondary.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _kPageBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kCardBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Iconify(e.value.icon, size: 14, color: _kBlue),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: Text(
                            e.value.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.value.value.isEmpty ? '—' : e.value.value,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: e.value.value.isEmpty
                                  ? _kTextSecondary.withOpacity(0.35)
                                  : _kTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: _kCardBorder,
                      indent: 12,
                      endIndent: 12,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditBody() {
    return SingleChildScrollView(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditSection('Organization', [
            _EditField(
              icon: Mdi.domain,
              label: 'Organization Name',
              ctrl: _orgCtrl,
              hint: 'Enter name',
            ),
            _EditField(
              icon: Mdi.account,
              label: 'Contact Person',
              ctrl: _personCtrl,
              hint: 'Enter person name',
            ),
            _EditField(
              icon: Mdi.map_marker,
              label: 'Address',
              ctrl: _addressCtrl,
              hint: 'Enter address',
              maxLines: 2,
            ),
          ]),
          const SizedBox(height: 12),
          _buildEditSection('Contact', [
            _EditField(
              icon: Mdi.email,
              label: 'Email',
              ctrl: _emailCtrl,
              hint: 'Enter email',
              keyboard: TextInputType.emailAddress,
            ),
            _EditField(
              icon: Mdi.phone,
              label: 'Phone',
              ctrl: _phoneCtrl,
              hint: 'Enter phone',
              keyboard: TextInputType.phone,
            ),
            _EditField(
              icon: Mdi.web,
              label: 'Website',
              ctrl: _websiteCtrl,
              hint: 'Enter website',
              keyboard: TextInputType.url,
            ),
          ]),
          const SizedBox(height: 16),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.profileCtrl.isSaving.value ? null : _saveEdit,
                icon: widget.profileCtrl.isSaving.value
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 15),
                label: Text(
                  widget.profileCtrl.isSaving.value
                      ? 'Saving…'
                      : 'Save Changes',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(String title, List<_EditField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _kTextSecondary.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...fields.asMap().entries.map(
          (e) => Padding(
            padding: EdgeInsets.only(
              bottom: e.key < fields.length - 1 ? 10 : 0,
            ),
            child: _buildEditField(e.value),
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(_EditField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Iconify(f.icon, size: 12, color: _kBlue),
            const SizedBox(width: 5),
            Text(
              f.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: f.ctrl,
          maxLines: f.maxLines,
          keyboardType: f.keyboard,
          style: const TextStyle(fontSize: 12.5, color: _kTextPrimary),
          decoration: InputDecoration(
            hintText: f.hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: _kTextSecondary.withOpacity(0.4),
            ),
            filled: true,
            fillColor: _kPageBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBlue, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  final String icon, label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _EditField {
  final String icon, label, hint;
  final TextEditingController ctrl;
  final int maxLines;
  final TextInputType keyboard;
  const _EditField({
    required this.icon,
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });
}

