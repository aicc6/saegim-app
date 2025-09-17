import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/home/data/models/support_inquiry_model.dart';
import 'package:saegim/features/home/data/services/support_inquiry_service.dart';

/// 고객센터 문의 상태
class SupportInquiryState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final SupportInquiryResponse? lastSubmittedInquiry;
  final List<SupportInquiryResponse> inquiries;

  const SupportInquiryState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.lastSubmittedInquiry,
    this.inquiries = const [],
  });

  SupportInquiryState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    SupportInquiryResponse? lastSubmittedInquiry,
    List<SupportInquiryResponse>? inquiries,
  }) {
    return SupportInquiryState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      lastSubmittedInquiry: lastSubmittedInquiry ?? this.lastSubmittedInquiry,
      inquiries: inquiries ?? this.inquiries,
    );
  }
}

/// 고객센터 문의 Notifier
class SupportInquiryNotifier extends StateNotifier<SupportInquiryState> {
  final SupportInquiryService _service;

  SupportInquiryNotifier(this._service) : super(const SupportInquiryState());

  /// 문의 등록
  Future<bool> submitInquiry(SupportInquiryRequest request) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final response = await _service.createInquiry(request);
      state = state.copyWith(
        isSubmitting: false,
        lastSubmittedInquiry: response,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// 내 문의 목록 로드
  Future<void> loadMyInquiries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final inquiries = await _service.getMyInquiries();
      state = state.copyWith(
        isLoading: false,
        inquiries: inquiries,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 상태 초기화
  void reset() {
    state = const SupportInquiryState();
  }
}

/// SupportInquiryNotifier Provider
final supportInquiryNotifierProvider =
    StateNotifierProvider<SupportInquiryNotifier, SupportInquiryState>((ref) {
      final service = ref.read(supportInquiryServiceProvider);
      return SupportInquiryNotifier(service);
    });
