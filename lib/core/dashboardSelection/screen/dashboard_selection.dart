// lib/core/dashboard/screens/dashboard_selection_screen.dart

import 'dart:io';
import 'dart:convert';

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/About/about_app_screen.dart';
import 'package:BisonsTechs_app/core/About/privacypolicy_screen.dart';
import 'package:BisonsTechs_app/core/About/termsofservice_screen.dart';
import 'package:BisonsTechs_app/core/Contact/Screens/Contact_Screen.dart';
import 'package:BisonsTechs_app/core/Feedback/feedback_screen.dart';
import 'package:BisonsTechs_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:BisonsTechs_app/core/Sales/screens/sales_dashbaord_screen.dart';
import 'package:BisonsTechs_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:BisonsTechs_app/core/Users/screen/user_list_screen.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/change_password_screen.dart';
import 'package:BisonsTechs_app/core/companyprofile/controller/profile_controller.dart';
import 'package:BisonsTechs_app/core/companyprofile/screen/company_profile_screen.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_dashboard_screen.dart';
import 'package:BisonsTechs_app/core/settings/screens/currency_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class TicketModel {
  final String id;
  final String title;
  final String date;
  final String description;
  final String status;
  final String priority;
  final int age;

  TicketModel({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.status,
    required this.priority,
    required this.age,
  });

  TicketModel copyWith({
    String? id,
    String? title,
    String? date,
    String? description,
    String? status,
    String? priority,
    int? age,
  }) {
    return TicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      age: age ?? this.age,
    );
  }
}

// ─── Support Controller ────────────────────────────────────────────────────

class SupportController extends GetxController {
  final tickets = <TicketModel>[].obs;
  final filteredTickets = <TicketModel>[].obs;
  final isAddingTicket = false.obs;
  final isEditingTicket = false.obs;
  final selectedTicket = Rxn<TicketModel>();
  final showTicketsDropdown = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Sample data
    tickets.addAll([
      TicketModel(
        id: 'T-04351',
        title: 'Software Integration Issue',
        date: '19/06/2026',
        description: 'Unable to integrate with accounting software',
        status: 'Open',
        priority: 'High',
        age: 3,
      ),
      TicketModel(
        id: 'T-04352',
        title: 'Invoice Generation Error',
        date: '18/06/2026',
        description: 'System generating duplicate invoices',
        status: 'In Progress',
        priority: 'Medium',
        age: 2,
      ),
      TicketModel(
        id: 'T-04353',
        title: 'Payment Gateway Issue',
        date: '17/06/2026',
        description: 'Payments not reflecting in system',
        status: 'Resolved',
        priority: 'High',
        age: 5,
      ),
      TicketModel(
        id: 'T-04354',
        title: 'Report Export Failing',
        date: '16/06/2026',
        description: 'Unable to export reports to PDF',
        status: 'Open',
        priority: 'Low',
        age: 1,
      ),
    ]);
    filteredTickets.value = tickets;
  }

  void addTicket(TicketModel ticket) {
    tickets.add(ticket);
    filteredTickets.value = tickets;
    isAddingTicket.value = false;
    showTicketsDropdown.value = true;
  }

  void updateTicket(TicketModel ticket) {
    final index = tickets.indexWhere((t) => t.id == ticket.id);
    if (index != -1) {
      tickets[index] = ticket;
      filteredTickets.value = tickets;
    }
    isEditingTicket.value = false;
    selectedTicket.value = null;
  }

  void deleteTicket(String id) {
    tickets.removeWhere((t) => t.id == id);
    filteredTickets.value = tickets;
  }

  void filterTickets({String? search}) {
    if (search == null || search.isEmpty) {
      filteredTickets.value = tickets;
      return;
    }
    filteredTickets.value = tickets
        .where(
          (t) =>
              t.title.toLowerCase().contains(search.toLowerCase()) ||
              t.id.toLowerCase().contains(search.toLowerCase()) ||
              t.status.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
  }

  void openAddTicket() {
    isAddingTicket.value = true;
    selectedTicket.value = null;
    showTicketsDropdown.value = true;
  }

  void openEditTicket(TicketModel ticket) {
    selectedTicket.value = ticket;
    isEditingTicket.value = true;
    showTicketsDropdown.value = true;
  }

  void closeTicketForm() {
    isAddingTicket.value = false;
    isEditingTicket.value = false;
    selectedTicket.value = null;
  }

  void toggleDropdown() {
    showTicketsDropdown.value = !showTicketsDropdown.value;
    if (!showTicketsDropdown.value) {
      isAddingTicket.value = false;
      isEditingTicket.value = false;
      selectedTicket.value = null;
    }
  }

  void closeDropdown() {
    showTicketsDropdown.value = false;
    isAddingTicket.value = false;
    isEditingTicket.value = false;
    selectedTicket.value = null;
  }

  String getNextTicketId() {
    if (tickets.isEmpty) return 'T-04351';
    final lastId = tickets.last.id;
    final numPart = int.parse(lastId.substring(2));
    return 'T-${(numPart + 1).toString().padLeft(5, '0')}';
  }
}

// ─── Main Screen ────────────────────────────────────────────────────────────

class DashboardSelectionScreen extends StatefulWidget {
  const DashboardSelectionScreen({super.key});

  @override
  State<DashboardSelectionScreen> createState() =>
      _DashboardSelectionScreenState();
}

class _DashboardSelectionScreenState extends State<DashboardSelectionScreen> {
  int _currentBanner = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _selectedIndex = 0;

  final ProfileController _profileCtrl = Get.put(ProfileController());

  late final SupportController _supportCtrl;
  
  String _businessLogo = '';

  @override
  void initState() {
    super.initState();
    _supportCtrl = Get.isRegistered<SupportController>()
        ? Get.find<SupportController>()
        : Get.put(SupportController());
    _loadBusinessLogo();
  }
  
  Future<void> _loadBusinessLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        final businessDetails = userData['businessDetails'] as Map<String, dynamic>?;
        
        if (businessDetails != null && businessDetails['logo'] != null) {
          final logo = businessDetails['logo'] as String;
          if (logo.isNotEmpty) {
            setState(() {
              _businessLogo = logo;
            });
            print('✅ [DashboardSelection] Business logo loaded: $logo');
          }
        }
      }
    } catch (e) {
      print('❌ [DashboardSelection] Error loading business logo: $e');
    }
  }

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Advanced Financial\nReports',
      'subtitle':
          'Cash flow, balance sheet & aged\nreceivables at your fingertips',
      'badge': 'NEW FEATURE',
      'btnText': 'Explore Reports',
      'imageUrl':
          'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=1200&q=80',
      'accentColor': const Color(0xFF00C2FF),
      'bgColor': const Color(0xFF0A2540),
    },
    {
      'title': 'Warehouse\nModule Live',
      'subtitle': 'Manage inventory, orders &\nstock all in one place',
      'badge': 'NOW LIVE',
      'btnText': 'Open Warehouse',
      'imageUrl':
          'https://images.unsplash.com/photo-1553413077-190dd305871c?w=1200&q=80',
      'accentColor': const Color(0xFF7C4DFF),
      'bgColor': const Color(0xFF1A1A2E),
    },
    {
      'title': 'Bank-Grade\nSecurity',
      'subtitle': 'Your financial data is encrypted\nand always protected',
      'badge': 'ALWAYS ON',
      'btnText': 'Learn More',
      'imageUrl':
          'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=1200&q=80',
      'accentColor': const Color(0xFF00E676),
      'bgColor': const Color(0xFF003322),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildTopBar(isMobile),
      drawer: isMobile ? _buildDrawer() : null,
      body: Stack(
        children: [
          isMobile
              ? _buildBanner(isMobile: true)
              : Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildSidebar(isTablet),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          right: 12,
                          bottom: 12,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildBanner(isMobile: false),
                        ),
                      ),
                    ),
                  ],
                ),
          // Support Tickets Dropdown Overlay
          Obx(() {
            if (!_supportCtrl.showTicketsDropdown.value) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: 70,
              right: isMobile ? 16 : 100,
              child: _buildTicketsDropdown(),
            );
          }),
        ],
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTopBar(bool isMobile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: isMobile
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _businessLogo.isNotEmpty
                      ? Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _businessLogo.startsWith('http')
                                ? Image.network(
                                    _businessLogo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.account_balance, color: kPrimary, size: 20);
                                    },
                                  )
                                : Image.file(
                                    File(_businessLogo),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.account_balance, color: kPrimary, size: 20);
                                    },
                                  ),
                          ),
                        )
                      : Icon(Icons.account_balance, color: kPrimary, size: 20),
                  const SizedBox(width: 6),
                  Obx(
                    () => Text(
                      _profileCtrl.organizationName.value.isEmpty
                          ? 'Company'
                          : _profileCtrl.organizationName.value,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
      leadingWidth: isMobile ? 56 : 160,
      title: isMobile
          ? Row(
              children: [
                _businessLogo.isNotEmpty
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _businessLogo.startsWith('http')
                              ? Image.network(
                                  _businessLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.account_balance, color: kPrimary, size: 18);
                                  },
                                )
                              : Image.file(
                                  File(_businessLogo),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.account_balance, color: kPrimary, size: 18);
                                  },
                                ),
                        ),
                      )
                    : Icon(Icons.account_balance, color: kPrimary, size: 18),
                const SizedBox(width: 6),
                Obx(
                  () => Text(
                    _profileCtrl.organizationName.value.isEmpty
                        ? 'Company'
                        : _profileCtrl.organizationName.value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _topBarAction(
                  icon: Icons.phone_outlined,
                  label: 'Call Us: 03 111 006 555',
                  color: kPrimary,
                ),
                const SizedBox(width: 8),
                _topBarDivider(),
                const SizedBox(width: 8),
                _topBarAction(
                  icon: Icons.headset_mic_outlined,
                  label: 'Support Ticket',
                  color: Colors.black87,
                  onTap: _toggleSupportDropdown,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                _topBarDivider(),
                const SizedBox(width: 8),

                const SizedBox(width: 8),
                _topBarDivider(),
                const SizedBox(width: 8),
              ],
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.black87,
                size: 20,
              ),
            ),
            onPressed: () {
              Get.to(() => const ProfileScreen());
            },
            tooltip: 'Profile',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  void _toggleSupportDropdown() {
    _supportCtrl.toggleDropdown();
  }

  Widget _topBarAction({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBarDivider() {
    return Container(width: 1, height: 18, color: Colors.grey.shade300);
  }

  // ─── Support Tickets Dropdown ────────────────────────────────────────

  Widget _buildTicketsDropdown() {
    return Obx(() {
      if (_supportCtrl.isAddingTicket.value ||
          _supportCtrl.isEditingTicket.value) {
        return _buildTicketForm();
      }
      return _buildTicketListDropdown();
    });
  }

  Widget _buildTicketListDropdown() {
    return Container(
      width: 680,
      constraints: const BoxConstraints(maxHeight: 450),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'Tickets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                // Search
                SizedBox(
                  width: 180,
                  child: TextField(
                    onChanged: (value) =>
                        _supportCtrl.filterTickets(search: value),
                    decoration: InputDecoration(
                      hintText: 'Search tickets...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _supportCtrl.openAddTicket,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Add Ticket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _supportCtrl.closeDropdown,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'FILTERS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'Number', icon: Icons.numbers),
                        const SizedBox(width: 6),
                        _FilterChip(label: 'Date', icon: Icons.calendar_today),
                        const SizedBox(width: 6),
                        _FilterChip(label: 'Title', icon: Icons.title),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Ticket Age',
                          icon: Icons.access_time,
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(label: 'Status', icon: Icons.label),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Priority',
                          icon: Icons.priority_high,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 60),
                Expanded(flex: 2, child: _buildHeaderText('Ticket')),
                Expanded(flex: 1, child: _buildHeaderText('Status')),
                Expanded(flex: 1, child: _buildHeaderText('Priority')),
                Expanded(flex: 1, child: _buildHeaderText('Age')),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Ticket list
          Expanded(
            child: Obx(() {
              if (_supportCtrl.filteredTickets.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _supportCtrl.filteredTickets.length,
                itemBuilder: (context, index) {
                  final ticket = _supportCtrl.filteredTickets[index];
                  return _TicketItem(
                    ticket: ticket,
                    onTap: () => _supportCtrl.openEditTicket(ticket),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            const Text(
              'No record found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first support ticket',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ticket Form ─────────────────────────────────────────────────────

  Widget _buildTicketForm() {
    return Container(
      width: 480,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _TicketFormWidget(
        supportCtrl: _supportCtrl,
        onClose: _supportCtrl.closeTicketForm,
      ),
    );
  }

  // ─── Sidebar ──────────────────────────────────────────────────────────

  Widget _buildSidebar(bool isTablet) {
    final double width = isTablet ? 64 : 210;
    final bool collapsed = isTablet;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _SidebarItemWidget(
            icon: Icons.home_outlined,
            label: 'Home',
            index: 0,
            selectedIndex: _selectedIndex,
            collapsed: collapsed,
            showArrow: false,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 8 : 16,
              vertical: 6,
            ),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'WORKSPACES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          if (PermissionService.to.hasModuleAccess('warehouse'))
            _SidebarItemWidget(
              icon: Icons.warehouse_outlined,
              label: 'Warehouse',
              index: 1,
              selectedIndex: _selectedIndex,
              collapsed: collapsed,
              showArrow: true,
              onTap: _navigateToWarehouse,
            ),
          if (PermissionService.to.hasModuleAccess('accounting'))
            _SidebarItemWidget(
              icon: Icons.account_balance_outlined,
              label: 'Accounting',
              index: 2,
              selectedIndex: _selectedIndex,
              collapsed: collapsed,
              showArrow: true,
              onTap: _navigateToAccounting,
            ),
          const Spacer(),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.help_outline, size: 18, color: kPrimary),
                    const SizedBox(height: 6),
                    Text(
                      'Need help?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contact our support team',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 272,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _DrawerHeader(profileCtrl: _profileCtrl),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              children: [
                _SectionLabel('WORKSPACES'),
                _NavSection(
                  title: 'Workspaces',
                  icon: Mdi.view_dashboard,
                  currentRoute: '',
                  modules: const [
                    'warehouse',
                    'accounting',
                    'sales',
                    'purchases',
                  ],
                  items: const [
                    ('Warehouse', Mdi.warehouse, '__warehouse'),
                    ('Accounting', Mdi.account_balance, '__accounting'),
                    ('Sales', Mdi.cart_outline, '__sales'),
                    ('Purchases', Mdi.cart_plus, '__purchase'),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('ADMINISTRATION'),
                _NavSection(
                  title: 'Users',
                  icon: Mdi.account_group,
                  currentRoute: '',
                  modules: const ['users'],
                  items: const [('Users', Mdi.account_multiple, '__users')],
                ),
                const SizedBox(height: 4),
                _SectionLabel('ACCOUNT'),
                _NavSection(
                  title: 'Settings',
                  icon: Mdi.cog,
                  currentRoute: '',
                  items: const [('Currency', Mdi.currency_usd, '__currency')],
                ),
                _NavSection(
                  title: 'My Account',
                  icon: Mdi.account,
                  currentRoute: '',
                  items: const [
                    ('My Profile', Mdi.account_circle_outline, '__profile'),
                    ('Change Password', Mdi.lock_reset, '__changepassword'),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('SUPPORT'),
                _NavSection(
                  title: 'Help & Support',
                  icon: Mdi.help_circle,
                  currentRoute: '',
                  items: const [
                    ('User Guide', Mdi.book_information_variant, '__userguide'),
                    ('Contact Support', Mdi.headset, '__contact'),
                    ('Report an Issue', Mdi.bug_outline, '__reportissue'),
                  ],
                ),
                _NavSection(
                  title: 'Feedback',
                  icon: Mdi.feedback,
                  currentRoute: '',
                  items: const [('Feedback', Mdi.feedback, '__feedback')],
                ),
                _NavSection(
                  title: 'Subscription',
                  icon: Mdi.crown,
                  currentRoute: '',
                  items: const [
                    ('Subscription Plans', Mdi.crown, '__subscription'),
                  ],
                ),
                _NavSection(
                  title: 'About',
                  icon: Mdi.information,
                  currentRoute: '',
                  items: const [
                    ('About App', Mdi.information_outline, '__about'),
                    ('Terms of Service', Mdi.file_sign, '__terms'),
                    ('Privacy Policy', Mdi.shield_lock_outline, '__privacy'),
                  ],
                ),
              ],
            ),
          ),
          _DrawerFooter(profileCtrl: _profileCtrl),
        ],
      ),
    );
  }

  // ─── Banner ───────────────────────────────────────────────────────────

  Widget _buildBanner({required bool isMobile}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double bannerHeight = constraints.maxHeight > 0
            ? constraints.maxHeight
            : (isMobile ? 400 : 600);

        return SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: _banners.length,
              options: CarouselOptions(
                height: bannerHeight,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 600),
                autoPlayCurve: Curves.easeInOut,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                padEnds: false,
                onPageChanged: (index, _) =>
                    setState(() => _currentBanner = index),
              ),
              itemBuilder: (context, index, realIndex) {
                final b = _banners[index];
                final bgColor = b['bgColor'] as Color;
                final accentColor = b['accentColor'] as Color;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      b['imageUrl'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: bgColor),
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: bgColor);
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            bgColor.withOpacity(0.95),
                            bgColor.withOpacity(0.65),
                            bgColor.withOpacity(0.15),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 52,
                        vertical: isMobile ? 24 : 48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: accentColor.withOpacity(0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              b['badge'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 14 : 20),
                          Text(
                            b['title'] as String,
                            style: TextStyle(
                              fontSize: isMobile ? 28 : 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: isMobile ? 10 : 16),
                          Text(
                            b['subtitle'] as String,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 16,
                              color: Colors.white60,
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 32),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 18 : 26,
                                vertical: isMobile ? 11 : 14,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    b['btnText'] as String,
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 15,
                                      fontWeight: FontWeight.w700,
                                      color: bgColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: bgColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_banners.length, (i) {
                          final active = i == _currentBanner;
                          return GestureDetector(
                            onTap: () => _carouselController.animateToPage(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _navigateToWarehouse() => Get.offAllNamed('/warehouse/dashboard');
  void _navigateToAccounting() => Get.offAllNamed('/accounting/dashboard');
  void _navigateToSales() => Get.to(() => SalesDashboardScreen());
  void _navigateToPurchase() => Get.to(() => PurchaseDashboardScreen());
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FilterChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const _TicketItem({required this.ticket, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Resolved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                ticket.id,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ticket.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(ticket.status),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getPriorityColor(ticket.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ticket.priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(ticket.priority),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${ticket.age}d',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─── Ticket Form Widget ────────────────────────────────────────────────────

class _TicketFormWidget extends StatefulWidget {
  final SupportController supportCtrl;
  final VoidCallback onClose;

  const _TicketFormWidget({required this.supportCtrl, required this.onClose});

  @override
  State<_TicketFormWidget> createState() => _TicketFormWidgetState();
}

class _TicketFormWidgetState extends State<_TicketFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedStatus = 'Open';
  String _selectedPriority = 'Medium';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.supportCtrl.selectedTicket.value;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _selectedStatus = existing.status;
      _selectedPriority = existing.priority;
      _selectedDate = DateFormat('dd/MM/yyyy').parse(existing.date);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supportCtrl.selectedTicket.value != null;
    final ticketId = isEditing
        ? widget.supportCtrl.selectedTicket.value!.id
        : widget.supportCtrl.getNextTicketId();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Text(
                isEditing
                    ? 'Ticket - Edit [$ticketId]'
                    : 'Ticket - Add [$ticketId]',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),

        // Form
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Title *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _titleController,
                    decoration: _buildInputDecoration('Title'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 12),

                  // Date
                  const Text(
                    'Date *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status & Priority Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildSmallDropdown(
                              value: _selectedStatus,
                              items: [
                                'Open',
                                'In Progress',
                                'Resolved',
                                'Closed',
                              ],
                              onChanged: (value) =>
                                  setState(() => _selectedStatus = value!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildSmallDropdown(
                              value: _selectedPriority,
                              items: ['Low', 'Medium', 'High', 'Urgent'],
                              onChanged: (value) =>
                                  setState(() => _selectedPriority = value!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Description *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _buildInputDecoration('Description'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter a description'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Attachments
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 28,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Drop files here or',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'BROWSE FILES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'CLOSE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text(
                            'SAVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildSmallDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 18),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTicket() {
    if (_formKey.currentState!.validate()) {
      final existing = widget.supportCtrl.selectedTicket.value;
      final ticket = TicketModel(
        id: existing?.id ?? widget.supportCtrl.getNextTicketId(),
        title: _titleController.text,
        date: DateFormat('dd/MM/yyyy').format(_selectedDate),
        description: _descriptionController.text,
        status: _selectedStatus,
        priority: _selectedPriority,
        age: existing?.age ?? 0,
      );

      if (existing != null) {
        widget.supportCtrl.updateTicket(ticket);
      } else {
        widget.supportCtrl.addTicket(ticket);
      }
      widget.onClose();
    }
  }
}

class _SidebarItemWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final bool collapsed;
  final bool showArrow;
  final VoidCallback onTap;

  const _SidebarItemWidget({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.collapsed,
    required this.showArrow,
    required this.onTap,
  });

  @override
  State<_SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<_SidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.selectedIndex == widget.index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 8 : 10,
            vertical: 2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? kPrimary.withOpacity(0.08)
                : _isHovered
                ? kPrimary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.collapsed
              ? Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      widget.icon,
                      key: ValueKey(widget.icon),
                      size: 22,
                      color: isActive
                          ? kPrimary
                          : _isHovered
                          ? kPrimary
                          : Colors.grey[500],
                    ),
                  ),
                )
              : Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        widget.icon,
                        key: ValueKey(widget.icon),
                        size: 20,
                        color: isActive
                            ? kPrimary
                            : _isHovered
                            ? kPrimary
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : _isHovered
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? kPrimary
                              : _isHovered
                              ? kPrimary
                              : Colors.black87,
                        ),
                        child: Text(widget.label),
                      ),
                    ),
                    if (widget.showArrow)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          key: ValueKey(widget.showArrow),
                          size: 13,
                          color: isActive
                              ? kPrimary
                              : _isHovered
                              ? kPrimary
                              : Colors.grey[400],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatefulWidget {
  final ProfileController profileCtrl;
  
  const _DrawerHeader({required this.profileCtrl});

  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader> {
  String _businessLogo = '';

  @override
  void initState() {
    super.initState();
    _loadBusinessLogo();
  }

  Future<void> _loadBusinessLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        final businessDetails = userData['businessDetails'] as Map<String, dynamic>?;
        
        if (businessDetails != null && businessDetails['logo'] != null) {
          final logo = businessDetails['logo'] as String;
          if (logo.isNotEmpty) {
            setState(() {
              _businessLogo = logo;
            });
            print('✅ [DrawerHeader] Business logo loaded: $logo');
          }
        }
      }
    } catch (e) {
      print('❌ [DrawerHeader] Error loading business logo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = widget.profileCtrl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: kPrimary),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Company avatar + name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _businessLogo.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _businessLogo.startsWith('http')
                            ? Image.network(
                                _businessLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.account_balance_rounded,
                                      color: Colors.black87,
                                      size: 22,
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(_businessLogo),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.account_balance_rounded,
                                      color: Colors.black87,
                                      size: 22,
                                    ),
                                  );
                                },
                              ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.account_balance_rounded,
                          color: Colors.black87,
                          size: 22,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        profileCtrl.organizationName.value.isEmpty
                            ? 'Company'
                            : profileCtrl.organizationName.value,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Dashboard Selection',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Plan badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Iconify(Mdi.shield_account, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  'Current Plan',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _NavSection extends StatefulWidget {
  final String title;
  final String icon;
  final String currentRoute;
  final List<(String, String, String)> items;
  final List<String>? modules;

  const _NavSection({
    required this.title,
    required this.icon,
    required this.currentRoute,
    required this.items,
    this.modules,
  });

  @override
  State<_NavSection> createState() => _NavSectionState();
}

class _NavSectionState extends State<_NavSection> {
  bool _expanded = false;
  final PermissionService _permissionService = PermissionService.to;

  bool get _hasActiveChild => widget.items.any((i) => _isActive(i.$3));

  List<(String, String, String)> get _filteredItems {
    if (widget.modules == null) {
      return widget.items;
    }

    final isAdmin = _permissionService.isAdmin;
    if (isAdmin) return widget.items;

    final filtered = <(String, String, String)>[];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final module = widget.modules![i];

      if (_permissionService.hasModuleAccess(module)) {
        filtered.add(item);
      }
    }
    return filtered;
  }

  bool _isActive(String routeKey) {
    if (routeKey.startsWith('__')) return false;
    return widget.currentRoute.toLowerCase().contains(routeKey.toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    _expanded = _hasActiveChild;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Iconify(
                  widget.icon,
                  size: 18,
                  color: _hasActiveChild ? kPrimary : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _hasActiveChild
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: _hasActiveChild ? Colors.black : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: _filteredItems.map((item) {
              return _NavItem(
                label: item.$1,
                icon: item.$2,
                isActive: _isActive(item.$3),
                onTap: () {
                  Navigator.pop(context);
                  _navigate(item.$3, item.$1);
                },
              );
            }).toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _navigate(String routeKey, String label) {
    switch (routeKey) {
      case '__warehouse':
        Get.offAllNamed('/warehouse/dashboard');
        break;
      case '__accounting':
        Get.offAllNamed('/accounting/dashboard');
        break;
      case '__sales':
        Get.to(() => const SalesDashboardScreen());
        break;
      case '__purchase':
        Get.to(() => const PurchaseDashboardScreen());
        break;
      case '__currency':
        Get.to(() => const CurrencyScreen());
        break;
      case '__profile':
        Get.to(() => const ProfileScreen());
        break;
      case '__changepassword':
        Get.to(() => const ChangePasswordScreen());
        break;
      case '__userguide':
        Get.to(() => const UserGuideScreen());
        break;
      case '__contact':
        Get.to(() => const ContactScreen());
        break;
      case '__reportissue':
        Get.to(() => const ReportIssueScreen());
        break;
      case '__feedback':
        Get.to(() => const FeedbackScreen());
        break;
      case '__subscription':
        Get.to(() => const SelectPlanScreen());
        break;
      case '__users':
        Get.to(() => const UserListScreen());
        break;
      case '__about':
        Get.to(() => const AboutAppScreen());
        break;
      case '__terms':
        Get.to(() => const TermsOfServiceScreen());
        break;
      case '__privacy':
        Get.to(() => const PrivacyPolicyScreen());
        break;
      default:
        Get.snackbar('Coming Soon', '$label coming soon');
    }
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? kPrimary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 14,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isActive ? kPrimary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Iconify(
              icon,
              size: 16,
              color: isActive ? kPrimary : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? kPrimary : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  final ProfileController profileCtrl;
  
  const _DrawerFooter({required this.profileCtrl});

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Get.offAll(() => const LoginScreen());
                        AppSnackbar.success(
                          kSuccess,
                          'Success',
                          'Logged out successfully',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimary, kPrimaryDark]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          profileCtrl.firstName.value.isEmpty
                              ? 'User'
                              : '${profileCtrl.firstName.value} ${profileCtrl.lastName.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Obx(
                        () => Text(
                          profileCtrl.organizationName.value.isEmpty
                              ? 'Premium Account'
                              : profileCtrl.organizationName.value,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Logout button
          InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Iconify(Mdi.logout, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade400,
                    ),
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
