import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key, this.items});

  final List<Map<String, dynamic>>? items;

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  late final List<Map<String, dynamic>> _notifications = [
    if (widget.items != null) ...widget.items!,
    if (widget.items == null) ...[
    {
      'title': 'Leave Request',
      'message': 'Ahmed Khan applied for casual leave (10-11 Sep)',
      'time': DateTime.now().subtract(const Duration(minutes: 12)),
      'icon': Icons.beach_access_rounded,
      'color': Colors.blue,
      'isRead': false,
    },
    {
      'title': 'Late Check-in',
      'message': 'Sara Ali checked in 25 minutes late',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'icon': Icons.warning_rounded,
      'color': kWarning,
      'isRead': false,
    },
    {
      'title': 'Payroll Ready',
      'message': 'September payroll has been generated',
      'time': DateTime.now().subtract(const Duration(hours: 5)),
      'icon': Icons.payments_rounded,
      'color': kSuccess,
      'isRead': true,
    },
    {
      'title': 'New Employee',
      'message': 'Fatima Noor was added to HR department',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'icon': Icons.person_add_rounded,
      'color': kPrimary,
      'isRead': true,
    },
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['isRead'] == false).length;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications Center',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            unread > 0 ? '$unread unread' : 'All caught up',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          for (final n in _notifications) {
                            n['isRead'] = true;
                          }
                        });
                      },
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Text('No notifications yet'),
                  )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final isRead = n['isRead'] as bool;
                final color = n['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => n['isRead'] = true),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRead
                            ? Colors.transparent
                            : color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(n['icon'] as IconData, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n['title'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n['message'] as String,
                                style: TextStyle(fontSize: 11, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(n['time'] as DateTime),
                          style: TextStyle(fontSize: 10, color: kSubText),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
