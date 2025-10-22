// emotion_store.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 감정 옵션 enum
enum EmotionOption {
  none('', '중립적인'),
  happy('happy', '밝고 긍정적인'),
  sad('sad', '차분하고 감성적인'),
  angry('angry', '강렬하고 직설적인'),
  peaceful('peaceful', '평온하고 안정적인'),
  unrest('unrest', '불안하고 조심스러운');

  const EmotionOption(this.value, this.tone);
  final String value;
  final String tone;
}

// 감정 설정 클래스
class EmotionConfig {
  final EmotionOption value;
  final String label;
  final String emoji;
  final EmotionStyles styles;

  const EmotionConfig({
    required this.value,
    required this.label,
    required this.emoji,
    required this.styles,
  });
}

class EmotionStyles {
  final String bg;
  final String text;
  final String ring;

  const EmotionStyles({
    required this.bg,
    required this.text,
    required this.ring,
  });
}

// 감정 설정 상수
const List<EmotionConfig> emotionConfigs = [
  EmotionConfig(
    value: EmotionOption.peaceful,
    label: '평온',
    emoji: '😌',
    styles: EmotionStyles(
      bg: 'bg-green-100',
      text: 'text-green-700',
      ring: 'ring-green-400',
    ),
  ),
  EmotionConfig(
    value: EmotionOption.happy,
    label: '행복',
    emoji: '😄',
    styles: EmotionStyles(
      bg: 'bg-yellow-100',
      text: 'text-yellow-700',
      ring: 'ring-yellow-400',
    ),
  ),
  EmotionConfig(
    value: EmotionOption.sad,
    label: '슬픔',
    emoji: '😢',
    styles: EmotionStyles(
      bg: 'bg-sky-100',
      text: 'text-sky-700',
      ring: 'ring-sky-400',
    ),
  ),
  EmotionConfig(
    value: EmotionOption.angry,
    label: '분노',
    emoji: '😠',
    styles: EmotionStyles(
      bg: 'bg-pink-100',
      text: 'text-pink-700',
      ring: 'ring-pink-400',
    ),
  ),
  EmotionConfig(
    value: EmotionOption.unrest,
    label: '불안',
    emoji: '😨',
    styles: EmotionStyles(
      bg: 'bg-purple-100',
      text: 'text-orange-700',
      ring: 'ring-purple-400',
    ),
  ),
];

// 감정 상태 클래스
class EmotionState {
  final List<EmotionConfig> emotions;
  final EmotionOption selectedEmotion;
  final List<EmotionOption> recentEmotions;

  const EmotionState({
    required this.emotions,
    required this.selectedEmotion,
    required this.recentEmotions,
  });

  EmotionState copyWith({
    List<EmotionConfig>? emotions,
    EmotionOption? selectedEmotion,
    List<EmotionOption>? recentEmotions,
  }) {
    return EmotionState(
      emotions: emotions ?? this.emotions,
      selectedEmotion: selectedEmotion ?? this.selectedEmotion,
      recentEmotions: recentEmotions ?? this.recentEmotions,
    );
  }

  // 유틸리티 메서드들
  EmotionConfig? getEmotionConfig(EmotionOption emotion) {
    return emotions.cast<EmotionConfig?>().firstWhere(
      (e) => e?.value == emotion,
      orElse: () => null,
    );
  }

  String getEmotionLabel(EmotionOption emotion) {
    final config = getEmotionConfig(emotion);
    return config?.label ?? emotion.value;
  }

  String getEmotionEmoji(EmotionOption emotion) {
    final config = getEmotionConfig(emotion);
    return config?.emoji ?? '';
  }

  EmotionOption detectTextEmotion(String text) {
    final lowerText = text.toLowerCase();

    if (RegExp(r'행복|기쁨|즐거').hasMatch(lowerText)) {
      return EmotionOption.happy;
    }
    if (RegExp(r'슬프|우울|눈물').hasMatch(lowerText)) {
      return EmotionOption.sad;
    }
    if (RegExp(r'화|분노|짜증').hasMatch(lowerText)) {
      return EmotionOption.angry;
    }
    if (RegExp(r'평온|고요|안정').hasMatch(lowerText)) {
      return EmotionOption.peaceful;
    }
    if (RegExp(r'불안|걱정|초조').hasMatch(lowerText)) {
      return EmotionOption.unrest;
    }

    return EmotionOption.none;
  }

  String getEmotionTone(EmotionOption emotion) {
    return emotion.tone;
  }
}

// 감정 상태 Notifier
class EmotionNotifier extends StateNotifier<EmotionState> {
  EmotionNotifier()
    : super(
        const EmotionState(
          emotions: emotionConfigs,
          selectedEmotion: EmotionOption.none,
          recentEmotions: [],
        ),
      ) {
    _loadState();
  }

  // SharedPreferences에서 상태 로드
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedEmotionValue = prefs.getString('selectedEmotion') ?? '';
      final recentEmotionsValues = prefs.getStringList('recentEmotions') ?? [];

      final selectedEmotion = EmotionOption.values.firstWhere(
        (e) => e.value == selectedEmotionValue,
        orElse: () => EmotionOption.none,
      );

      final recentEmotions = recentEmotionsValues
          .map(
            (value) => EmotionOption.values.firstWhere(
              (e) => e.value == value,
              orElse: () => EmotionOption.none,
            ),
          )
          .where((e) => e != EmotionOption.none)
          .toList();

      state = state.copyWith(
        selectedEmotion: selectedEmotion,
        recentEmotions: recentEmotions,
      );
    } catch (e) {
      print('감정 상태 로드 실패: $e');
    }
  }

  // SharedPreferences에 상태 저장
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedEmotion', state.selectedEmotion.value);
      await prefs.setStringList(
        'recentEmotions',
        state.recentEmotions.map((e) => e.value).toList(),
      );
    } catch (e) {
      print('감정 상태 저장 실패: $e');
    }
  }

  // 감정 선택
  void setSelectedEmotion(EmotionOption emotion) {
    state = state.copyWith(selectedEmotion: emotion);
    addToRecent(emotion);
    _saveState();
  }

  // 감정 토글
  void toggleEmotion(EmotionOption emotion) {
    final newEmotion = state.selectedEmotion == emotion
        ? EmotionOption.none
        : emotion;
    state = state.copyWith(selectedEmotion: newEmotion);

    if (newEmotion != EmotionOption.none) {
      addToRecent(newEmotion);
    }
    _saveState();
  }

  // 감정 선택 해제
  void clearEmotion() {
    state = state.copyWith(selectedEmotion: EmotionOption.none);
    _saveState();
  }

  // 최근 감정에 추가
  void addToRecent(EmotionOption emotion) {
    if (emotion == EmotionOption.none) return;

    final newRecent = [
      emotion,
      ...state.recentEmotions.where((e) => e != emotion),
    ].take(5).toList(); // 최근 5개만 유지

    state = state.copyWith(recentEmotions: newRecent);
  }
}

// Provider 정의
final emotionProvider = StateNotifierProvider<EmotionNotifier, EmotionState>(
  (ref) => EmotionNotifier(),
);
