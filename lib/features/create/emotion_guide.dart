import 'package:flutter/material.dart';

import '../home/presentation/riverpod/emotions_notifier.dart';

class EmotionGuide extends StatelessWidget {
  final EmotionOption? emotion;
  final List<EmotionConfig> emotionConfigs;
  final EmotionConfig? Function(EmotionOption?) getEmotionConfig;

  const EmotionGuide({
    super.key,
    required this.emotion,
    required this.emotionConfigs,
    required this.getEmotionConfig,
  });

  @override
  Widget build(BuildContext context) {
    final selectedConfig = emotion != null ? getEmotionConfig(emotion) : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 추측 감정 표시
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                children: [
                  const TextSpan(text: 'AI가 추측한 감정은 '),
                  TextSpan(
                    text: emotion != null
                        ? (selectedConfig?.label ??
                              emotion.toString().split('.').last)
                        : '감정 선택 안함',
                    style: TextStyle(
                      color: emotion != null
                          ? Colors.blue.shade600
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (emotion != null && selectedConfig?.emoji != null)
                    TextSpan(
                      text: selectedConfig!.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  const TextSpan(text: ' 입니다.'),
                ],
              ),
            ),
          ),

          // 안내 메시지
          Text(
            '다른 감정을 원하시면 아래에 선택해 주세요',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// 사용 예시 - emotion_guide_example.dart

class EmotionGuideExample extends StatefulWidget {
  const EmotionGuideExample({super.key});

  @override
  State<EmotionGuideExample> createState() => _EmotionGuideExampleState();
}

class _EmotionGuideExampleState extends State<EmotionGuideExample> {
  EmotionOption? selectedEmotion = EmotionOption.happy;

  Color _getColorFromStyle(String style) {
    // bg-{color}-100 또는 text-{color}-700 형식의 스타일에서 색상 추출
    final parts = style.split('-');
    if (parts.length != 3) return Colors.grey;

    final color = parts[1];
    final shade = int.tryParse(parts[2]) ?? 500;

    switch (color) {
      case 'yellow':
        return Colors.yellow[shade] ?? Colors.yellow;
      case 'blue':
        return Colors.blue[shade] ?? Colors.blue;
      case 'red':
        return Colors.red[shade] ?? Colors.red;
      case 'green':
        return Colors.green[shade] ?? Colors.green;
      case 'orange':
        return Colors.orange[shade] ?? Colors.orange;
      default:
        return Colors.grey[shade] ?? Colors.grey;
    }
  }

  final List<EmotionConfig> emotionConfigs = const [
    EmotionConfig(
      value: EmotionOption.happy,
      label: '행복',
      emoji: '😊',
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
        bg: 'bg-blue-100',
        text: 'text-blue-700',
        ring: 'ring-blue-400',
      ),
    ),
    EmotionConfig(
      value: EmotionOption.angry,
      label: '화남',
      emoji: '😡',
      styles: EmotionStyles(
        bg: 'bg-red-100',
        text: 'text-red-700',
        ring: 'ring-red-400',
      ),
    ),
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
      value: EmotionOption.unrest,
      label: '불안',
      emoji: '😨',
      styles: EmotionStyles(
        bg: 'bg-orange-100',
        text: 'text-orange-700',
        ring: 'ring-orange-400',
      ),
    ),
  ];

  EmotionConfig? getEmotionConfig(EmotionOption? emotion) {
    if (emotion == null) return null;
    try {
      return emotionConfigs.firstWhere((config) => config.value == emotion);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('감정 가이드 예시')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // EmotionGuide 위젯 사용
            EmotionGuide(
              emotion: selectedEmotion,
              emotionConfigs: emotionConfigs,
              getEmotionConfig: getEmotionConfig,
            ),

            const SizedBox(height: 24),

            // 감정 선택 버튼들
            const Text(
              '감정을 선택해보세요:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...emotionConfigs.map(
                  (config) => ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedEmotion = config.value;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedEmotion == config.value
                          ? _getColorFromStyle(config.styles.bg)
                          : Colors.grey.shade100,
                      foregroundColor: selectedEmotion == config.value
                          ? _getColorFromStyle(config.styles.text)
                          : Colors.grey.shade700,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          config.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 4),
                        Text(config.label),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedEmotion = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedEmotion == null
                        ? Colors.grey.shade300
                        : Colors.grey.shade100,
                  ),
                  child: const Text('선택 안함'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
