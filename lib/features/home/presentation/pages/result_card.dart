import 'dart:io';

import 'package:flutter/material.dart';

// 타입 정의
class GeneratedMessage {
  final String id;
  final List<MessageVersion> versions;
  final int currentVersionIndex;

  GeneratedMessage({
    required this.id,
    required this.versions,
    this.currentVersionIndex = 0,
  });
}

class MessageVersion {
  final String text;
  final String? emotion;
  final String length;
  final String style;
  final List<File>? images;
  final List<String>? keywords;

  MessageVersion({
    required this.text,
    this.emotion,
    required this.length,
    required this.style,
    this.images,
    this.keywords,
  });
}

class EmotionConfig {
  final String emoji;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  EmotionConfig({
    required this.emoji,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

class MessageCard extends StatefulWidget {
  final GeneratedMessage message;
  final bool isRegenerating;
  final EmotionConfig? Function(String emotion) getEmotionConfig;
  final String Function(String style) getStyleDisplayName;
  final String Function(String length) getLengthDisplayName;
  final Function(String content) onCopy;
  final Function(String content, String? emotion, List<String>? keywords)
  onMoveToDiary;
  final Function(GeneratedMessage message) onRegenerate;
  final Function(String messageId) onPreviousVersion;
  final Function(String messageId) onNextVersion;

  const MessageCard({
    super.key,
    required this.message,
    required this.isRegenerating,
    required this.getEmotionConfig,
    required this.getStyleDisplayName,
    required this.getLengthDisplayName,
    required this.onCopy,
    required this.onMoveToDiary,
    required this.onRegenerate,
    required this.onPreviousVersion,
    required this.onNextVersion,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentVersion =
        widget.message.versions[widget.message.currentVersionIndex];
    final hasMultipleVersions = widget.message.versions.length > 1;

    if (widget.isRegenerating) {
      return _buildLoadingCard();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(currentVersion),
          if (hasMultipleVersions) ...[
            const SizedBox(height: 16),
            _buildVersionNavigation(),
          ],
          if (currentVersion.images != null &&
              currentVersion.images!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImages(currentVersion.images!),
          ],
          const SizedBox(height: 16),
          _buildContent(currentVersion),
          if (currentVersion.keywords != null &&
              currentVersion.keywords!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildKeywords(currentVersion.keywords!),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(currentVersion),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로딩 텍스트
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF3F764A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '글을 생성하고 있습니다...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSkeletonLine(0.4),
          const SizedBox(height: 12),
          _buildSkeletonLine(1.0),
          const SizedBox(height: 12),
          _buildSkeletonLine(0.9),
          const SizedBox(height: 12),
          _buildSkeletonLine(0.8),
          const SizedBox(height: 12),
          _buildSkeletonLine(0.95),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine(double widthFactor) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: 16,
          width: double.infinity * widthFactor,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                0.0,
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
                1.0,
              ].map((v) => v.clamp(0.0, 1.0)).toList(),
              colors: [
                Colors.grey[200]!,
                Colors.grey[200]!,
                Colors.grey[100]!,
                Colors.grey[200]!,
                Colors.grey[200]!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MessageVersion currentVersion) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('생성된 글', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Row(
          children: [
            if (currentVersion.emotion != null) ...[
              _buildEmotionChip(currentVersion.emotion!),
              const SizedBox(width: 8),
            ],
            _buildChip(widget.getLengthDisplayName(currentVersion.length)),
            const SizedBox(width: 8),
            _buildChip(widget.getStyleDisplayName(currentVersion.style)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmotionChip(String emotion) {
    // 🔍 result_card에서 emotion 처리 디버그 로그
    print('🔍 result_card - emotion 처리:');
    print('  - 입력 emotion: $emotion');
    print('  - emotion 타입: ${emotion.runtimeType}');

    final emotionConfig = widget.getEmotionConfig(emotion);
    print('  - emotionConfig: ${emotionConfig?.label}');
    print('  - emotionConfig emoji: ${emotionConfig?.emoji}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emotionConfig?.backgroundColor ?? const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${emotionConfig?.emoji ?? ''} ${emotionConfig?.label ?? emotion}',
        style: TextStyle(
          fontSize: 12,
          color: emotionConfig?.textColor ?? Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildVersionNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: widget.message.currentVersionIndex == 0
              ? null
              : () => widget.onPreviousVersion(widget.message.id),
          icon: Icon(
            Icons.chevron_left,
            size: 20,
            color: widget.message.currentVersionIndex == 0
                ? Colors.grey[400]
                : Colors.grey[700],
          ),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        Text(
          '${widget.message.currentVersionIndex + 1} / ${widget.message.versions.length}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed:
              widget.message.currentVersionIndex ==
                  widget.message.versions.length - 1
              ? null
              : () => widget.onNextVersion(widget.message.id),
          icon: Icon(
            Icons.chevron_right,
            size: 20,
            color:
                widget.message.currentVersionIndex ==
                    widget.message.versions.length - 1
                ? Colors.grey[400]
                : Colors.grey[700],
          ),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildImages(List<File> images) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.asMap().entries.map((entry) {
        final index = entry.key;
        final image = entry.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(MessageVersion currentVersion) {
    if (currentVersion.style == 'poem') {
      final lines = currentVersion.text.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Text(
                line,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                  height: 1.6,
                ),
              ),
            )
            .toList(),
      );
    }

    return Text(
      currentVersion.text,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF374151),
        height: 1.6,
      ),
    );
  }

  Widget _buildKeywords(List<String> keywords) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: double.infinity, height: 1, color: Colors.grey[100]),
        const SizedBox(height: 16),
        Text('키워드:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords
              .map(
                (keyword) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    keyword,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF22543D),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(MessageVersion currentVersion) {
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            text: '복사하기',
            onPressed: () => widget.onCopy(currentVersion.text),
            enabled: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ActionButton(
            text: '다이어리로 이동',
            onPressed: () => widget.onMoveToDiary(
              currentVersion.text,
              currentVersion.emotion,
              currentVersion.keywords,
            ),
            enabled: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ActionButton(
            text: _getRegenerateButtonText(),
            onPressed: widget.message.versions.length >= 5
                ? null
                : () => widget.onRegenerate(widget.message),
            enabled: widget.message.versions.length < 5,
          ),
        ),
      ],
    );
  }

  String _getRegenerateButtonText() {
    if (widget.message.versions.length == 1) {
      return '다시 생성';
    } else if (widget.message.versions.length >= 5) {
      return '최대 재생성 횟수 도달 (${widget.message.versions.length}번)';
    } else {
      return '다시 생성 ';
    }
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  const ActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? Colors.blue[50] : Colors.grey[100],
        foregroundColor: enabled ? Colors.blue[700] : Colors.grey[400],
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: enabled ? Colors.blue[200]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
