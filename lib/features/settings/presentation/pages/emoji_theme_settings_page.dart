import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/theme/theme_extensions.dart';

import '../../../../core/constants/emotion_emoji_config.dart';
import '../../../../core/providers/emoji_theme_provider.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/emotion_emoji_widget.dart';

/// 이모지 테마 설정 페이지
class EmojiThemeSettingsPage extends ConsumerWidget {
  const EmojiThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emojiTheme = ref.watch(emojiThemeProvider);

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, title: '이모지 스타일 설정'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '앱 전체에서 사용되는 감정 이모지 스타일을 선택하세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.primaryText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 현재 선택된 스타일
            Text(
              '현재 스타일: ${emojiTheme.styleName}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // 스타일 선택 카드들
            ...EmotionEmojiConfig.availableStyles.map(
              (style) => _buildStyleCard(
                context,
                ref,
                style,
                isSelected: emojiTheme.currentStyle == style,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 스타일 선택 카드
  Widget _buildStyleCard(
    BuildContext context,
    WidgetRef ref,
    String style, {
    required bool isSelected,
  }) {
    final styleName = EmotionEmojiConfig.getStyleName(style);
    final styleEmojis = EmotionEmojiConfig.getStyleEmojis(style);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? context.colorScheme.primary
              : context.borderSubtle,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: context.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () {
          ref.read(emojiThemeProvider.notifier).setStyle(style);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 스타일 이름과 선택 표시
              Row(
                children: [
                  Text(
                    styleName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.primaryText,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: context.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '선택됨',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // 이모지 미리보기
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEmojiPreview('행복', styleEmojis['happy']!, context),
                  _buildEmojiPreview('슬픔', styleEmojis['sad']!, context),
                  _buildEmojiPreview('분노', styleEmojis['angry']!, context),
                  _buildEmojiPreview('평온', styleEmojis['peaceful']!, context),
                  _buildEmojiPreview('불안', styleEmojis['unrest']!, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이모지 미리보기
  Widget _buildEmojiPreview(
    String label,
    String emojiOrPath,
    BuildContext context,
  ) {
    return Column(
      children: [
        // 이모지 또는 이미지
        DirectEmojiWidget(
          emojiOrPath: emojiOrPath,
          size: 32,
          imageScale: 1.3, // PNG 미리보기는 1.3배 크게
        ),
        const SizedBox(height: 4),
        // 라벨
        Text(
          label,
          style: TextStyle(fontSize: 10, color: context.secondaryText),
        ),
      ],
    );
  }
}
