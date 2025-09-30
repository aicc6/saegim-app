import 'package:flutter/material.dart';

enum EmotionType { happy, sad, angry, peaceful, unrest }

class EmotionLabel {
  final String emoji;
  final String name;
  final Color color;
  final Color backgroundColor;
  final Color textColor;

  const EmotionLabel({
    required this.emoji,
    required this.name,
    required this.color,
    this.backgroundColor = const Color(0xFFE8F5E8),
    this.textColor = const Color(0xFF22543D),
  });
}

const Map<EmotionType, EmotionLabel> emotionLabels = {
  EmotionType.happy: EmotionLabel(
    emoji: '😊',
    name: '행복',
    color: Colors.yellow,
  ),
  EmotionType.sad: EmotionLabel(emoji: '😢', name: '슬픔', color: Colors.blue),
  EmotionType.angry: EmotionLabel(emoji: '😡', name: '화남', color: Colors.red),
  EmotionType.peaceful: EmotionLabel(
    emoji: '😌',
    name: '평온',
    color: Colors.green,
  ),
  EmotionType.unrest: EmotionLabel(
    emoji: '😨',
    name: '불안',
    color: Colors.orange,
  ),
};

String getEmotionName(String? emotionType) {
  if (emotionType == null) return '알 수 없음';

  try {
    final emotion = EmotionType.values.firstWhere(
      (e) => e.toString().split('.').last == emotionType,
      orElse: () => EmotionType.happy,
    );
    return emotionLabels[emotion]?.name ?? '알 수 없음';
  } catch (e) {
    return '알 수 없음';
  }
}

String getEmotionEmoji(String? emotionType) {
  if (emotionType == null) return '😐';

  try {
    final emotion = EmotionType.values.firstWhere(
      (e) => e.toString().split('.').last == emotionType,
      orElse: () => EmotionType.happy,
    );
    return emotionLabels[emotion]?.emoji ?? '😐';
  } catch (e) {
    return '😐';
  }
}
