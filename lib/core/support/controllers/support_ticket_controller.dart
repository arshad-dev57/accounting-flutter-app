import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/support/models/support_ticket_model.dart';
import 'package:get/get.dart';

class SupportTicketController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final tickets = <SupportTicketModel>[].obs;
  final filteredTickets = <SupportTicketModel>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;

  final categories = const [
    'Bug',
    'Crash',
    'Performance',
    'UI Issue',
    'Data Error',
    'Billing',
    'Feature Request',
    'General',
    'Other',
  ];

  final priorities = const ['Low', 'Medium', 'High', 'Critical'];
  final statuses = const ['Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  Future<void> loadTickets() async {
    isLoading.value = true;
    try {
      final params = <String, String>{
        'limit': '50',
      };
      if (selectedStatus.value != 'all') {
        params['status'] = selectedStatus.value;
      }
      if (searchQuery.value.trim().isNotEmpty) {
        params['search'] = searchQuery.value.trim();
      }

      final res = await _api.get(
        '/api/support/tickets',
        queryParameters: params,
      );
      if (!res.success) {
        throw Exception(res.message);
      }

      final body = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      final raw = body['data'];
      final list = (raw is List ? raw : <dynamic>[])
          .map((e) => SupportTicketModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      tickets.assignAll(list);
      filteredTickets.assignAll(list);
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadTickets();
  }

  void search(String q) {
    searchQuery.value = q;
    loadTickets();
  }

  Future<bool> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    String steps = '',
    String? attachmentPath,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      AppSnackbar.error(kDanger, 'Error', 'Title and description are required');
      return false;
    }

    isSubmitting.value = true;
    try {
      final fields = {
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'priority': priority,
        'stepsToReproduce': steps.trim(),
      };

      final Map<String, String>? files =
          attachmentPath != null && attachmentPath.isNotEmpty
              ? {'attachment': attachmentPath}
              : null;

      final res = await _api.postMultipart(
        '/api/support/tickets',
        fields: fields,
        filePaths: files,
      );

      if (!res.success) {
        throw Exception(res.message);
      }

      AppSnackbar.success(kSuccess, 'Success', 'Support ticket submitted');
      await loadTickets();
      return true;
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteTicket(String id) async {
    try {
      final res = await _api.delete('/api/support/tickets/$id');
      if (!res.success) throw Exception(res.message);
      AppSnackbar.success(kSuccess, 'Deleted', 'Ticket removed');
      await loadTickets();
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', e.toString());
    }
  }
}
