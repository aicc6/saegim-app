import 'package:permission_handler/permission_handler.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// STT(Speech-to-Text) 서비스
/// 음성 인식 기능을 제공하고 권한 처리를 담당합니다.
class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;

  /// 현재 음성 인식 중인지 확인
  bool get isListening => _isListening;

  /// STT 서비스 초기화
  ///
  /// Returns: 초기화 성공 여부
  Future<bool> initialize() async {
    try {
      // 마이크 권한 확인
      final permissionStatus = await Permission.microphone.status;

      if (permissionStatus.isDenied) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          AppLogger.error('Microphone permission denied', tag: 'SttService');
          return false;
        }
      }

      // Speech-to-Text 초기화
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          AppLogger.error('STT Error: ${error.errorMsg}', tag: 'SttService');
          _isListening = false;
        },
        onStatus: (status) {
          AppLogger.info('STT Status: $status', 'SttService');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        AppLogger.info('STT Service initialized successfully', 'SttService');
      } else {
        AppLogger.error('Failed to initialize STT Service', tag: 'SttService');
      }

      return _isInitialized;
    } catch (e) {
      AppLogger.error('STT initialization error: $e', tag: 'SttService');
      return false;
    }
  }

  /// 음성 인식 시작
  ///
  /// [onResult]: 인식된 텍스트를 받는 콜백
  /// [localeId]: 언어 설정 (기본값: 한국어)
  /// [partialResults]: 실시간으로 중간 결과를 받을지 여부
  Future<void> startListening({
    required Function(String recognizedText) onResult,
    String localeId = 'ko-KR',
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Failed to initialize STT service');
      }
    }

    if (_isListening) {
      AppLogger.info('Already listening', 'SttService');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          final recognizedWords = result.recognizedWords;
          AppLogger.info(
            'Recognized: $recognizedWords (Final: ${result.finalResult})',
            'SttService',
          );
          onResult(recognizedWords);
        },
        localeId: localeId,
        partialResults: partialResults,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      AppLogger.info('Started listening', 'SttService');
    } catch (e) {
      AppLogger.error('Failed to start listening: $e', tag: 'SttService');
      _isListening = false;
      rethrow;
    }
  }

  /// 음성 인식 중지
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      await _speechToText.stop();
      _isListening = false;
      AppLogger.info('Stopped listening', 'SttService');
    } catch (e) {
      AppLogger.error('Failed to stop listening: $e', tag: 'SttService');
      rethrow;
    }
  }

  /// 음성 인식 취소
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      AppLogger.info('Cancelled listening', 'SttService');
    } catch (e) {
      AppLogger.error('Failed to cancel listening: $e', tag: 'SttService');
      rethrow;
    }
  }

  /// 사용 가능한 언어 목록 가져오기
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    final locales = await _speechToText.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  /// 리소스 정리
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
    _isInitialized = false;
    _isListening = false;
  }
}
