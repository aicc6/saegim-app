import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/emotion_emoji_config.dart';

/// 이모티콘 테마 상태
class EmojiThemeState {
  final String currentStyle;
  final bool isLoading;

  const EmojiThemeState({required this.currentStyle, this.isLoading = false});

  EmojiThemeState copyWith({String? currentStyle, bool? isLoading}) {
    return EmojiThemeState(
      currentStyle: currentStyle ?? this.currentStyle,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 특정 감정의 이모티콘 가져오기
  String getEmoji(String emotion) {
    return EmotionEmojiConfig.getEmoji(emotion, style: currentStyle);
  }

  /// 현재 스타일 이름
  String get styleName => EmotionEmojiConfig.getStyleName(currentStyle);
}

/// 이모티콘 테마 Notifier
class EmojiThemeNotifier extends StateNotifier<EmojiThemeState> {
  static const String _storageKey = 'emoji_theme_style';

  EmojiThemeNotifier()
    : super(
        const EmojiThemeState(currentStyle: EmotionEmojiConfig.styleDefault),
      ) {
    _loadSavedStyle();
  }

  /// 저장된 스타일 로드
  Future<void> _loadSavedStyle() async {
    try {
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();
      final savedStyle =
          prefs.getString(_storageKey) ?? EmotionEmojiConfig.styleDefault;

      // 유효한 스타일인지 확인
      final validStyle = EmotionEmojiConfig.availableStyles.contains(savedStyle)
          ? savedStyle
          : EmotionEmojiConfig.styleDefault;

      state = state.copyWith(currentStyle: validStyle, isLoading: false);
    } catch (e) {
      print('이모티콘 스타일 로드 실패: $e');
      state = state.copyWith(
        currentStyle: EmotionEmojiConfig.styleDefault,
        isLoading: false,
      );
    }
  }

  /// 스타일 변경
  Future<void> setStyle(String style) async {
    if (!EmotionEmojiConfig.availableStyles.contains(style)) {
      print('유효하지 않은 이모티콘 스타일: $style');
      return;
    }

    try {
      state = state.copyWith(currentStyle: style);

      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, style);
    } catch (e) {
      print('이모티콘 스타일 저장 실패: $e');
    }
  }

  /// 다음 스타일로 순환
  Future<void> cycleStyle() async {
    final currentIndex = EmotionEmojiConfig.availableStyles.indexOf(
      state.currentStyle,
    );
    final nextIndex =
        (currentIndex + 1) % EmotionEmojiConfig.availableStyles.length;
    final nextStyle = EmotionEmojiConfig.availableStyles[nextIndex];

    await setStyle(nextStyle);
  }
}

/// 이모티콘 테마 Provider
final emojiThemeProvider =
    StateNotifierProvider<EmojiThemeNotifier, EmojiThemeState>(
      (ref) => EmojiThemeNotifier(),
    );

/// 특정 감정의 이모티콘을 가져오는 편의 Provider
///
/// 사용 예: `ref.watch(getEmojiProvider('happy'))`
final getEmojiProvider = Provider.family<String, String>((ref, emotion) {
  final emojiTheme = ref.watch(emojiThemeProvider);
  return emojiTheme.getEmoji(emotion);
});

