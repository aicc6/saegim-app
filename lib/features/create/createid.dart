import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/stt_service.dart';
import '../home/presentation/riverpod/emotions_notifier.dart';
import '../shared/widgets/keyword_editor.dart';
import 'emotion_guide.dart';

// models/diary_models.dart

class DiaryEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? aiGeneratedText;
  final String? userEmotion;
  final String? aiEmotion;
  final double? aiEmotionConfidence;
  final List<String> keywords;
  final String diaryDate;
  final String createdAt;
  final String updatedAt;
  final bool isPublic;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.aiGeneratedText,
    this.userEmotion,
    this.aiEmotion,
    this.aiEmotionConfidence,
    required this.keywords,
    required this.diaryDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublic,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // 🔍 emotion 데이터 디버그 로그
    print('🔍 DiaryEntry.fromJson - emotion 데이터 확인:');
    print('  - json["user_emotion"]: ${json["user_emotion"]}');
    print('  - json["ai_emotion"]: ${json["ai_emotion"]}');
    print(
      '  - json["ai_emotion_confidence"]: ${json["ai_emotion_confidence"]}',
    );

    return DiaryEntry(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      aiGeneratedText: json['ai_generated_text'],
      userEmotion: json['user_emotion'],
      aiEmotion: json['ai_emotion'],
      aiEmotionConfidence: json['ai_emotion_confidence']?.toDouble(),
      keywords: List<String>.from(json['keywords'] ?? []),
      diaryDate: json['diary_date'] ?? json['created_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isPublic: json['is_public'] ?? false,
    );
  }

  DiaryEntry copyWith({
    String? title,
    String? content,
    String? aiGeneratedText,
    String? userEmotion,
    List<String>? keywords,
  }) {
    return DiaryEntry(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      aiGeneratedText: aiGeneratedText ?? this.aiGeneratedText,
      userEmotion: userEmotion ?? this.userEmotion,
      aiEmotion: aiEmotion,
      aiEmotionConfidence: aiEmotionConfidence,
      keywords: keywords ?? this.keywords,
      diaryDate: diaryDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublic: isPublic,
    );
  }
}

class DiaryListEntry {
  final String id;
  final String title;
  final String content;
  final String? aiGeneratedText;
  final String? userEmotion;
  final String? aiEmotion;
  final List<String> keywords;
  final String? diaryDate;
  final String createdAt;

  DiaryListEntry({
    required this.id,
    required this.title,
    required this.content,
    this.aiGeneratedText,
    this.userEmotion,
    this.aiEmotion,
    required this.keywords,
    this.diaryDate,
    required this.createdAt,
  });

  factory DiaryListEntry.fromJson(Map<String, dynamic> json) {
    return DiaryListEntry(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      aiGeneratedText: json['ai_generated_text'],
      userEmotion: json['user_emotion'],
      aiEmotion: json['ai_emotion'],
      keywords: List<String>.from(json['keywords'] ?? []),
      diaryDate: json['diary_date'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// providers/diary_providers.dart
class DiaryState {
  final List<DiaryListEntry> diaries;
  final DiaryEntry? currentDiary;
  final bool isLoading;
  final DiaryEntry? tempEntry;

  DiaryState({
    this.diaries = const [],
    this.currentDiary,
    this.isLoading = false,
    this.tempEntry,
  });

  DiaryState copyWith({
    List<DiaryListEntry>? diaries,
    DiaryEntry? currentDiary,
    bool? isLoading,
    DiaryEntry? tempEntry,
    bool clearCurrentDiary = false,
    bool clearTempEntry = false,
  }) {
    return DiaryState(
      diaries: diaries ?? this.diaries,
      currentDiary: clearCurrentDiary
          ? null
          : (currentDiary ?? this.currentDiary),
      isLoading: isLoading ?? this.isLoading,
      tempEntry: clearTempEntry ? null : (tempEntry ?? this.tempEntry),
    );
  }
}

class DiaryNotifier extends StateNotifier<DiaryState> {
  final Dio _dio;

  DiaryNotifier(this._dio) : super(DiaryState());

  Future<void> fetchDiary(String entryId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.get('/api/diary/$entryId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final diary = DiaryEntry.fromJson(response.data['data']);
        state = state.copyWith(currentDiary: diary, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
        throw Exception('Failed to fetch diary');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateDiary(String entryId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/api/diary/$entryId', data: updates);
      if (response.statusCode != 200) {
        throw Exception('Failed to update diary');
      }

      // Update local state
      if (state.currentDiary != null) {
        final updatedDiary = state.currentDiary!.copyWith(
          title: updates['title'],
          content: updates['content'],
          userEmotion: updates['user_emotion'],
          keywords: updates['keywords']?.cast<String>(),
        );

        state = state.copyWith(currentDiary: updatedDiary);

        // Update diaries list
        final updatedDiaries = state.diaries.map((diary) {
          if (diary.id == entryId) {
            return DiaryListEntry(
              id: diary.id,
              title: updates['title'] ?? diary.title,
              content: updates['content'] ?? diary.content,
              aiGeneratedText: diary.aiGeneratedText,
              userEmotion: updates['user_emotion'] ?? diary.userEmotion,
              aiEmotion: diary.aiEmotion,
              keywords: updates['keywords']?.cast<String>() ?? diary.keywords,
              diaryDate: diary.diaryDate,
              createdAt: diary.createdAt,
            );
          }
          return diary;
        }).toList();

        state = state.copyWith(diaries: updatedDiaries);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDiary(String entryId) async {
    try {
      final response = await _dio.delete('/api/diary/$entryId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete diary');
      }

      // Remove from local state
      final updatedDiaries = state.diaries
          .where((diary) => diary.id != entryId)
          .toList();
      state = state.copyWith(diaries: updatedDiaries, clearCurrentDiary: true);
    } catch (e) {
      rethrow;
    }
  }

  void setTempEntry(DiaryEntry? entry) {
    state = state.copyWith(tempEntry: entry);
  }

  void clearTempEntry() {
    state = state.copyWith(clearTempEntry: true);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.baseUrl =
      'http://localhost:8000'; // Replace with your API base URL
  dio.options.connectTimeout = const Duration(seconds: 5);
  dio.options.receiveTimeout = const Duration(seconds: 3);
  return dio;
});

final diaryProvider = StateNotifierProvider<DiaryNotifier, DiaryState>((ref) {
  return DiaryNotifier(ref.watch(dioProvider));
});

// widgets/view_post_page.dart

class ViewPostPage extends ConsumerStatefulWidget {
  final String entryId;
  final String? fromPath;
  final String? year;
  final String? month;

  const ViewPostPage({
    super.key,
    required this.entryId,
    this.fromPath,
    this.year,
    this.month,
  });

  @override
  ConsumerState<ViewPostPage> createState() => _ViewPostPageState();
}

class _ViewPostPageState extends ConsumerState<ViewPostPage> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _keywordController;
  String _editedEmotion = '';
  List<String> _editedKeywords = [];
  int _currentIndex = 0;
  List<DiaryListEntry> _sameDateEntries = [];
  bool _deleteModalOpen = false;
  bool _showEmotionSelector = false;

  // STT 관련 상태
  final SttService _sttService = SttService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _keywordController = TextEditingController();
    _initializePage();
    _initializeStt();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _keywordController.dispose();
    _sttService.dispose();
    super.dispose();
  }

  /// STT 서비스 초기화
  Future<void> _initializeStt() async {
    await _sttService.initialize();
  }

  /// 음성 인식 토글
  Future<void> _toggleStt() async {
    if (_isListening) {
      // 음성 인식 중지
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      try {
        // 음성 인식 시작
        await _sttService.startListening(
          onResult: (text) {
            // 인식된 텍스트를 현재 커서 위치에 추가
            final currentText = _contentController.text;
            final selection = _contentController.selection;

            final newText = currentText.replaceRange(
              selection.start,
              selection.end,
              text,
            );

            _contentController.text = newText;

            // 커서를 추가된 텍스트 끝으로 이동
            _contentController.selection = TextSelection.fromPosition(
              TextPosition(offset: selection.start + text.length),
            );
          },
        );

        setState(() {
          _isListening = true;
        });
      } catch (e) {
        // 권한 또는 초기화 실패 시 스낵바 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('음성 인식을 시작할 수 없습니다. 마이크 권한을 확인해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _initializePage() async {
    final diaryState = ref.read(diaryProvider);

    // Find entry in diaries list for temp display
    final foundEntry = diaryState.diaries.cast<DiaryListEntry?>().firstWhere(
      (e) => e?.id == widget.entryId,
      orElse: () => null,
    );

    if (foundEntry != null && diaryState.tempEntry == null) {
      final tempEntry = DiaryEntry(
        id: foundEntry.id,
        userId: '',
        title: foundEntry.title,
        content: foundEntry.content,
        aiGeneratedText: foundEntry.aiGeneratedText,
        userEmotion: foundEntry.userEmotion,
        aiEmotion: foundEntry.aiEmotion,
        keywords: foundEntry.keywords,
        diaryDate: foundEntry.diaryDate ?? foundEntry.createdAt,
        createdAt: foundEntry.createdAt,
        updatedAt: foundEntry.createdAt,
        isPublic: false,
      );
      ref.read(diaryProvider.notifier).setTempEntry(tempEntry);
    }

    // Fetch diary details
    try {
      await ref.read(diaryProvider.notifier).fetchDiary(widget.entryId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('다이어리를 불러오는데 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Find same date entries
    if (diaryState.diaries.isNotEmpty && foundEntry != null) {
      final foundEntryDate =
          foundEntry.diaryDate?.split('T')[0] ??
          foundEntry.createdAt.split('T')[0];
      _sameDateEntries = diaryState.diaries.where((e) {
        final entryDate =
            e.diaryDate?.split('T')[0] ?? e.createdAt.split('T')[0];
        return entryDate == foundEntryDate;
      }).toList();

      _currentIndex = _sameDateEntries.indexWhere(
        (e) => e.id == widget.entryId,
      );
      if (_currentIndex == -1) _currentIndex = 0;
    }
  }

  void _handleEdit() async {
    final diaryState = ref.read(diaryProvider);
    final entry = diaryState.currentDiary;

    if (_isEditing && entry != null) {
      // Save changes
      try {
        await ref.read(diaryProvider.notifier).updateDiary(entry.id, {
          'title': _titleController.text,
          'content': _contentController.text,
          'user_emotion': _editedEmotion.isEmpty ? null : _editedEmotion,
          'keywords': _editedKeywords,
        });

        setState(() {
          _isEditing = false;
          _showEmotionSelector = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('다이어리가 성공적으로 저장되었습니다.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('다이어리 수정에 실패했습니다: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (!_isEditing && entry != null) {
      // Start editing
      setState(() {
        _isEditing = true;
        _titleController.text = entry.title;
        _contentController.text = entry.aiGeneratedText ?? entry.content;
        _editedEmotion = entry.userEmotion ?? '';
        _editedKeywords = List.from(entry.keywords);
      });
    }
  }

  void _handleCancelEdit() {
    final entry = ref.read(diaryProvider).currentDiary;
    if (entry != null) {
      setState(() {
        _isEditing = false;
        _showEmotionSelector = false;
        _titleController.text = entry.title;
        _contentController.text = entry.aiGeneratedText ?? entry.content;
        _editedEmotion = entry.userEmotion ?? '';
        _editedKeywords = List.from(entry.keywords);
      });
    }
  }

  void _handleDelete() {
    setState(() {
      _deleteModalOpen = true;
    });
  }

  Future<void> _handleDeleteConfirm() async {
    final entry = ref.read(diaryProvider).currentDiary;
    if (entry == null) return;

    try {
      await ref.read(diaryProvider.notifier).deleteDiary(entry.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('다이어리가 성공적으로 삭제되었습니다.')));

        setState(() {
          _deleteModalOpen = false;
        });

        if (widget.fromPath == '/create') {
          Navigator.of(context).pushReplacementNamed('/list');
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('다이어리 삭제 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNavigate(String direction) {
    if (direction == 'prev' && _currentIndex > 0) {
      final prevEntry = _sameDateEntries[_currentIndex - 1];
      ref
          .read(diaryProvider.notifier)
          .setTempEntry(ref.read(diaryProvider).currentDiary);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewPostPage(
            entryId: prevEntry.id,
            fromPath: widget.fromPath,
            year: widget.year,
            month: widget.month,
          ),
        ),
      );
    } else if (direction == 'next' &&
        _currentIndex < _sameDateEntries.length - 1) {
      final nextEntry = _sameDateEntries[_currentIndex + 1];
      ref
          .read(diaryProvider.notifier)
          .setTempEntry(ref.read(diaryProvider).currentDiary);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewPostPage(
            entryId: nextEntry.id,
            fromPath: widget.fromPath,
            year: widget.year,
            month: widget.month,
          ),
        ),
      );
    }
  }

  EmotionOption? _getEmotionType(String? emotion) {
    if (emotion == null) return null;

    // 🔍 emotion 변환 디버그 로그
    print('🔍 _getEmotionType - emotion 변환:');
    print('  - 입력 emotion: $emotion');
    print('  - emotion 타입: ${emotion.runtimeType}');

    try {
      final result = EmotionOption.values.firstWhere(
        (e) => e.toString().split('.').last == emotion,
      );
      print('  - 변환 결과: $result');
      return result;
    } catch (e) {
      print('  - 변환 실패: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(diaryProvider);
    final entry = diaryState.currentDiary;

    // Show temp entry while loading
    if (entry == null && diaryState.tempEntry != null) {
      return _buildLoadingView(diaryState.tempEntry!);
    }

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('다이어리')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('기록을 찾을 수 없습니다.'), SizedBox(height: 16)],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: InputBorder.none,
                ),
              )
            : Text(entry.title.isEmpty ? '제목 없음' : entry.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date display
                Text(
                  '${DateTime.parse(entry.diaryDate).month}월 ${DateTime.parse(entry.diaryDate).day}일',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Emotion and Keywords Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emotion Section
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '사용자 감정: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_isEditing)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _showEmotionSelector =
                                            !_showEmotionSelector,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _editedEmotion.isNotEmpty
                                                  ? emotionConfigs
                                                        .firstWhere(
                                                          (config) =>
                                                              config.value ==
                                                              _getEmotionType(
                                                                _editedEmotion,
                                                              ),
                                                          orElse: () =>
                                                              emotionConfigs
                                                                  .first,
                                                        )
                                                        .emoji
                                                  : '😐',
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _editedEmotion.isNotEmpty
                                                    ? emotionConfigs
                                                          .firstWhere(
                                                            (config) =>
                                                                config.value ==
                                                                _getEmotionType(
                                                                  _editedEmotion,
                                                                ),
                                                            orElse: () =>
                                                                emotionConfigs
                                                                    .first,
                                                          )
                                                          .label
                                                    : '선택하세요',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (entry.userEmotion != null) ...[
                                          Text(
                                            emotionConfigs
                                                .firstWhere(
                                                  (config) =>
                                                      config.value ==
                                                      _getEmotionType(
                                                        entry.userEmotion,
                                                      ),
                                                  orElse: () =>
                                                      emotionConfigs.first,
                                                )
                                                .emoji,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              emotionConfigs
                                                  .firstWhere(
                                                    (config) =>
                                                        config.value ==
                                                        _getEmotionType(
                                                          entry.userEmotion,
                                                        ),
                                                    orElse: () =>
                                                        emotionConfigs.first,
                                                  )
                                                  .label,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ] else
                                          const Expanded(
                                            child: Text('설정되지 않음'),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (entry.aiEmotion != null) ...[
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  // 🔍 AI emotion 표시 디버그 로그
                                  print('🔍 AI emotion 표시:');
                                  print(
                                    '  - entry.aiEmotion: ${entry.aiEmotion}',
                                  );
                                  print(
                                    '  - entry.aiEmotionConfidence: ${entry.aiEmotionConfidence}',
                                  );

                                  final emotionType = _getEmotionType(
                                    entry.aiEmotion,
                                  );
                                  print('  - emotionType: $emotionType');

                                  final emotionConfig = emotionConfigs
                                      .firstWhere(
                                        (config) => config.value == emotionType,
                                        orElse: () => emotionConfigs.first,
                                      );
                                  print(
                                    '  - emotionConfig: ${emotionConfig.label}',
                                  );

                                  return Row(
                                    children: [
                                      const Text(
                                        'AI 분석 감정: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        emotionConfig.emoji,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          emotionConfig.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (entry.aiEmotionConfidence != null)
                                        Text(
                                          ' (${(entry.aiEmotionConfidence! * 100).round()}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Keywords Section
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeywordEditor(
                              keywords: _isEditing
                                  ? _editedKeywords
                                  : entry.keywords,
                              onKeywordsChanged: (keywords) {
                                setState(() {
                                  _editedKeywords = keywords;
                                });
                              },
                              isEditing: _isEditing,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Emotion Selector Modal
                if (_showEmotionSelector && _isEditing)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    child: EmotionGuide(
                      emotion: _getEmotionType(_editedEmotion),
                      emotionConfigs: emotionConfigs,
                      getEmotionConfig: (emotion) {
                        if (emotion == null) return null;
                        try {
                          return emotionConfigs.firstWhere(
                            (config) => config.value == emotion,
                          );
                        } catch (e) {
                          return null;
                        }
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                const SizedBox(height: 24),

                // Content Section
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: _isEditing ? Colors.white : Colors.green.shade50,
                  ),
                  child: _isEditing
                      ? Column(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _contentController,
                                maxLines: null,
                                expands: true,
                                decoration: const InputDecoration(
                                  hintText: '[글 본문]',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            // STT 버튼
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _isListening ? '음성 인식 중...' : '음성으로 입력하기',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _toggleStt,
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                    ),
                                    color: _isListening
                                        ? Colors.red
                                        : Colors.green.shade600,
                                    style: IconButton.styleFrom(
                                      backgroundColor: _isListening
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                    ),
                                    tooltip: _isListening
                                        ? '음성 인식 중지'
                                        : '음성으로 입력',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            entry.aiGeneratedText ?? '[글 본문]',
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Navigation and Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    CircleAvatar(
                      backgroundColor: _currentIndex > 0
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                      child: IconButton(
                        onPressed: _currentIndex > 0
                            ? () => _handleNavigate('prev')
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        color: _currentIndex > 0
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                    ),

                    // Action Buttons
                    Row(
                      children: [
                        if (_isEditing) ...[
                          ElevatedButton.icon(
                            onPressed: _handleEdit,
                            icon: const Icon(Icons.check),
                            label: const Text('저장'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _handleCancelEdit,
                            icon: const Icon(Icons.close),
                            label: const Text('취소'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _handleEdit,
                            icon: const Icon(Icons.edit),
                            label: const Text('수정'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _handleDelete,
                            icon: const Icon(Icons.delete),
                            label: const Text('삭제'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Next Button
                    CircleAvatar(
                      backgroundColor:
                          _currentIndex < _sameDateEntries.length - 1
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                      child: IconButton(
                        onPressed: _currentIndex < _sameDateEntries.length - 1
                            ? () => _handleNavigate('next')
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        color: _currentIndex < _sameDateEntries.length - 1
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete Confirmation Modal
          if (_deleteModalOpen)
            Material(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '다이어리 삭제',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"${entry.title.isEmpty ? '제목 없음' : entry.title}"을(를) 정말 삭제하시겠습니까?',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _deleteModalOpen = false),
                            child: const Text('취소'),
                          ),
                          ElevatedButton(
                            onPressed: diaryState.isLoading
                                ? null
                                : _handleDeleteConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                            ),
                            child: diaryState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('삭제'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(DiaryEntry tempEntry) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tempEntry.title.isEmpty ? '제목 없음' : tempEntry.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Opacity(
              opacity: 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateTime.parse(tempEntry.diaryDate).month}월 ${DateTime.parse(tempEntry.diaryDate).day}일',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // Emotion and Keywords Section (placeholder)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '사용자 감정: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('😐', style: TextStyle(fontSize: 20)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'AI 분석 감정: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('😐', style: TextStyle(fontSize: 20)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '키워드: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Chip(label: Text('로딩 중...')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Content placeholder
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green.shade50,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        tempEntry.aiGeneratedText ??
                            (tempEntry.content.isNotEmpty
                                ? tempEntry.content
                                : '[글 본문]'),
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '다이어리를 불러오는 중...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
