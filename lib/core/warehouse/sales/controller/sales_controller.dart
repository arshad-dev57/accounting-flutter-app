import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/core/warehouse/sales/model/sales_dashboard_model.dart';
import 'package:get/get.dart';

class SalesController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxString period = 'month'.obs;
  final Rx<SalesDashboardModel?> dashboard = Rx<SalesDashboardModel?>(null);

  static const periods = ['today', 'week', 'month'];

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      final response = await _api.get(
        '/api/warehouse/sales/dashboard',
        queryParameters: {'period': period.value},
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        dashboard.value = SalesDashboardModel.fromJson(Map<String, dynamic>.from(response.data['data'] ?? {}));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void setPeriod(String p) {
    period.value = p;
    fetchDashboard();
  }

  void navigateTo(String route) => Get.toNamed(route);
}
