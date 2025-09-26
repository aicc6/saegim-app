import 'package:flutter/material.dart';

class KeywordEditor extends StatefulWidget {
  final List<String> keywords;
  final Function(List<String>) onKeywordsChanged;
  final bool isEditing;

  const KeywordEditor({
    super.key,
    required this.keywords,
    required this.onKeywordsChanged,
    this.isEditing = true,
  });

  @override
  State<KeywordEditor> createState() => _KeywordEditorState();
}

class _KeywordEditorState extends State<KeywordEditor> {
  final TextEditingController _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _handleAddKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !widget.keywords.contains(keyword)) {
      final updatedKeywords = [...widget.keywords, keyword];
      widget.onKeywordsChanged(updatedKeywords);
      _keywordController.clear();
    }
  }

  void _handleRemoveKeyword(String keyword) {
    final updatedKeywords = widget.keywords.where((k) => k != keyword).toList();
    widget.onKeywordsChanged(updatedKeywords);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('키워드: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.isEditing) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.keywords
                  .map(
                    (keyword) => Chip(
                      label: Text('#$keyword'),
                      onDeleted: () => _handleRemoveKeyword(keyword),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    onSubmitted: (value) => _handleAddKeyword(),
                    decoration: const InputDecoration(
                      hintText: '새 키워드 입력',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleAddKeyword,
                  child: const Text('추가'),
                ),
              ],
            ),
          ] else
            widget.keywords.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.keywords
                        .map((keyword) => Chip(label: Text('#$keyword')))
                        .toList(),
                  )
                : const Text('설정되지 않음'),
        ],
      ),
    );
  }
}
