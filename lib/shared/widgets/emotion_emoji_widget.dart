import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/emotion_emoji_config.dart';
import '../../core/providers/emoji_theme_provider.dart';

/// 감정 이모지 표시 위젯
///
/// 텍스트 이모지와 이미지 이모지를 모두 지원합니다.
/// 현재 선택된 이모지 테마에 따라 자동으로 표시됩니다.
class EmotionEmojiWidget extends ConsumerWidget {
  /// 감정 타입 (happy, sad, angry, peaceful, unrest)
  final String emotion;

  /// 이모지 크기 (텍스트 이모지에 적용)
  final double size;

  /// 이미지 스케일 배율 (이미지 이모지일 때 size에 곱함, 기본값 1.0)
  final double imageScale;

  /// 이미지 fit 방식 (이미지 스타일일 때만 적용)
  final BoxFit? fit;

  const EmotionEmojiWidget({
    super.key,
    required this.emotion,
    this.size = 24,
    this.imageScale = 1.0,
    this.fit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 이모지 테마 가져오기
    final emojiTheme = ref.watch(emojiThemeProvider);
    final emojiOrPath = emojiTheme.getEmoji(emotion);

    // 이미지 경로인지 확인
    if (EmotionEmojiConfig.isImagePath(emojiOrPath)) {
      final imageSize = size * imageScale; // 이미지 스케일 적용
      return Image.asset(
        emojiOrPath,
        width: imageSize,
        height: imageSize,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 이미지 로드 실패 시 기본 이모지 표시
          return Text('😐', style: TextStyle(fontSize: size));
        },
      );
    }

    // 텍스트 이모지 표시
    return Text(emojiOrPath, style: TextStyle(fontSize: size));
  }
}

/// 감정 이모지를 직접 지정하는 위젯 (테마 무시)
///
/// 특정 이모지를 강제로 표시하고 싶을 때 사용합니다.
class DirectEmojiWidget extends StatelessWidget {
  /// 이모지 문자열 또는 이미지 경로
  final String emojiOrPath;

  /// 이모지 크기 (텍스트 이모지에 적용)
  final double size;

  /// 이미지 스케일 배율 (이미지 이모지일 때 size에 곱함, 기본값 1.0)
  final double imageScale;

  /// 이미지 fit 방식 (이미지 경로일 때만 적용)
  final BoxFit? fit;

  const DirectEmojiWidget({
    super.key,
    required this.emojiOrPath,
    this.size = 24,
    this.imageScale = 1.0,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    // 이미지 경로인지 확인
    if (EmotionEmojiConfig.isImagePath(emojiOrPath)) {
      final imageSize = size * imageScale; // 이미지 스케일 적용
      return Image.asset(
        emojiOrPath,
        width: imageSize,
        height: imageSize,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text('😐', style: TextStyle(fontSize: size));
        },
      );
    }

    // 텍스트 이모지 표시
    return Text(emojiOrPath, style: TextStyle(fontSize: size));
  }
}
