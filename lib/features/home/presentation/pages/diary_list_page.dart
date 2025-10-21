import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/calendar/data/models/diary_image_model.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/features/home/data/models/diary_category_model.dart';
import 'package:saegim/features/home/data/services/diary_category_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:saegim/shared/widgets/emotion_emoji_widget.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedEmotion = 'all';
  String _dateFilter = 'all';
  String _sortOrder = 'desc';
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  bool _hasMore = true;
  final List<DiaryEntry> _allDiaries = [];
  final List<DiaryEntry> _displayedDiaries = [];
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  bool _selectionMode = false;
  final Set<String> _selectedDiaryIds = {};
  bool _isBulkDeleting = false;

  // 다이어리별 이미지 캐시
  final Map<String, List<DiaryImage>> _diaryImagesCache = {};
  final Set<String> _loadingImages = {};

  static const String _defaultCategoryKey = '__default__';
  static const String _allCategoryValue = '__all__';
  static const String _createCategoryValue = '__create__';
  List<DiaryCategory> _categories = [];
  Map<String, String> _categoryAssignments = {};
  String? _selectedCategoryId;
  bool _isLoadingCategories = false;
  // 초기 로드 완료 플래그
  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);

    // 쿼리 파라미터에서 새로고침 요청 확인 (안전한 방법)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final uri = GoRouterState.of(context).uri;
      final refreshParam = uri.queryParameters['refresh'];
      AppLogger.info('Current URI: ${uri.toString()}', 'DiaryListPage');
      AppLogger.info('Refresh parameter: $refreshParam', 'DiaryListPage');

      if (refreshParam != null) {
        AppLogger.info(
          'Refresh parameter detected: $refreshParam - executing refresh',
          'DiaryListPage',
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            AppLogger.info('Executing _refreshData() now', 'DiaryListPage');
            _refreshData();
          }
        });
      } else {
        AppLogger.info('No refresh parameter found', 'DiaryListPage');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 초기 로드 완료 후에만 새로고침 (다른 페이지에서 돌아올 때)
    if (_isInitialLoadComplete) {
      final uri = GoRouterState.of(context).uri;
      final refreshParam = uri.queryParameters['refresh'];

      if (refreshParam != null) {
        AppLogger.info(
          'didChangeDependencies - Refresh parameter detected: $refreshParam',
          'DiaryListPage',
        );
        // 약간의 지연 후 새로고침 실행
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            AppLogger.info(
              'didChangeDependencies - Executing refresh',
              'DiaryListPage',
            );
            _refreshData();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  /// 데이터 새로고침 (캘린더 페이지와 동일한 방식)
  Future<void> _refreshData() async {
    AppLogger.info('_refreshData() called - starting refresh', 'DiaryListPage');
    await _loadInitialData();
    AppLogger.info('_refreshData() completed', 'DiaryListPage');
  }

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _displayedDiaries.clear();
      // 새로고침 시 캐시 클리어 (캘린더 페이지와 동일)
      _diaryImagesCache.clear();
      _loadingImages.clear();
      _selectionMode = false;
      _selectedDiaryIds.clear();
      _isBulkDeleting = false;
    });

    await _loadCategories();
    await _loadDiariesFromAPI();

    // 초기 로드 완료 플래그 설정
    _isInitialLoadComplete = true;
  }

  /// API에서 다이어리 데이터 로드
  Future<void> _loadDiariesFromAPI() async {
    try {
      AppLogger.info('Loading diaries - Page: $_currentPage', 'DiaryListPage');

      // 검색어와 필터 조건 준비
      String? searchTerm = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      String? emotion = _selectedEmotion == 'all' ? null : _selectedEmotion;

      DateTime? startDate;
      DateTime? endDate;

      // 날짜 필터 처리
      if (_dateFilter != 'all') {
        final now = DateTime.now();
        switch (_dateFilter) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = startDate;
            break;
          case 'week':
            startDate = now.subtract(const Duration(days: 7));
            endDate = now;
            break;
          case 'month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            endDate = now;
            break;
          case 'custom':
            startDate = _startDate;
            endDate = _endDate;
            break;
        }
      }

      // 백엔드 API 호출 (페이지네이션 포함)
      final diaries = await DiaryApiService.instance.getDiariesWithFilters(
        page: _currentPage,
        pageSize: _itemsPerPage,
        searchTerm: searchTerm,
        emotion: emotion,
        startDate: startDate,
        endDate: endDate,
        sortOrder: _sortOrder,
      );

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _displayedDiaries.clear();
            _allDiaries.clear();
          }

          if (diaries != null && diaries.isNotEmpty) {
            _allDiaries.addAll(diaries);

            final filtered = _filterDiaries(_allDiaries);
            _displayedDiaries
              ..clear()
              ..addAll(filtered);
            final validIds =
                _displayedDiaries.map((diary) => diary.id).whereType<String>().toSet();
            _selectedDiaryIds.removeWhere((id) => !validIds.contains(id));

            // 백엔드에서 반환된 데이터가 요청한 페이지 크기보다 적으면 더 이상 데이터가 없음
            _hasMore = diaries.length >= _itemsPerPage;

            AppLogger.info(
              'Loaded ${diaries.length} diaries for page $_currentPage',
              'DiaryListPage',
            );
          } else {
            if (_currentPage == 1) {
              _displayedDiaries.clear();
            }
            _hasMore = false;
            AppLogger.info('No more diaries to load', 'DiaryListPage');
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load diaries from API',
        tag: 'DiaryListPage',
        error: e,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  /// 더 많은 아이템 로드 (무한스크롤)
  void _loadMoreItems() {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _currentPage++;
    });

    _loadDiariesFromAPI();
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _isLoadingCategories = true;
      });
    }

    try {
      final categoryService = DiaryCategoryService.instance;
      final categories = await categoryService.getCategories();
      final assignments = await categoryService.getAssignments();

      final filtered = _filterDiaries(
        _allDiaries,
        assignments: assignments,
        categoryId: _selectedCategoryId,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _categoryAssignments = assignments;
          _displayedDiaries
            ..clear()
            ..addAll(filtered);
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load diary categories',
        tag: 'DiaryListPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  List<DiaryEntry> _filterDiaries(
    List<DiaryEntry> source, {
    Map<String, String>? assignments,
    String? categoryId,
  }) {
    final resolvedAssignments = assignments ?? _categoryAssignments;
    final targetCategoryId = categoryId ?? _selectedCategoryId;

    if (targetCategoryId == null) {
      return List<DiaryEntry>.from(source);
    }

    if (targetCategoryId == _defaultCategoryKey) {
      return source
          .where((diary) => !resolvedAssignments.containsKey(diary.id))
          .toList();
    }

    return source
        .where((diary) => resolvedAssignments[diary.id] == targetCategoryId)
        .toList();
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      final filtered = _filterDiaries(_allDiaries);
      _displayedDiaries
        ..clear()
        ..addAll(filtered);
    });
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    String? errorText;
    bool isSaving = false;

    final createdCategory = await showDialog<DiaryCategory>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('새 다이어리 만들기'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '다이어리 이름',
                  errorText: errorText,
                ),
                enabled: !isSaving,
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            setState(() {
                              errorText = '다이어리 이름을 입력해주세요.';
                            });
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          try {
                            final category = await DiaryCategoryService.instance
                                .createCategory(name);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop(category);
                          } catch (_) {
                            setState(() {
                              isSaving = false;
                              errorText =
                                  '다이어리를 만들지 못했습니다. 다시 시도해주세요.';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('생성'),
                ),
              ],
            );
          },
        );
      },
    );

    if (createdCategory != null && mounted) {
      setState(() {
        _selectedCategoryId = createdCategory.id;
      });
      await _loadCategories();
    }
  }

  /// 필터 적용 (새로운 검색)
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _displayedDiaries.clear();
      _allDiaries.clear();
    });

    _loadDiariesFromAPI();
  }

  /// 다이어리 이미지 로드
  Future<void> _loadDiaryImages(String diaryId) async {
    // 이미 로딩 중이거나 캐시에 있으면 스킵
    if (_loadingImages.contains(diaryId) ||
        _diaryImagesCache.containsKey(diaryId)) {
      return;
    }

    _loadingImages.add(diaryId);

    try {
      final images = await DiaryApiService.instance.getDiaryImages(diaryId);

      if (mounted) {
        setState(() {
          _diaryImagesCache[diaryId] = images;
          _loadingImages.remove(diaryId);
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load images for diary: $diaryId',
        tag: 'DiaryListPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          _diaryImagesCache[diaryId] = [];
          _loadingImages.remove(diaryId);
        });
      }
    }
  }

  int get _selectableDiaryCount =>
      _displayedDiaries.where((diary) => diary.id != null).length;

  bool get _hasSelection => _selectedDiaryIds.isNotEmpty;

  bool get _isAllVisibleSelected =>
      _hasSelection &&
      _selectedDiaryIds.length == _selectableDiaryCount &&
      _selectableDiaryCount > 0;

  void _enterSelectionMode([String? diaryId]) {
    if (_displayedDiaries.isEmpty) {
      return;
    }

    setState(() {
      _selectionMode = true;
      _selectedDiaryIds.clear();
      if (diaryId != null) {
        _selectedDiaryIds.add(diaryId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedDiaryIds.clear();
    });
  }

  void _toggleDiarySelection(String? diaryId) {
    if (diaryId == null) {
      return;
    }

    setState(() {
      if (_selectedDiaryIds.contains(diaryId)) {
        _selectedDiaryIds.remove(diaryId);
      } else {
        _selectedDiaryIds.add(diaryId);
      }
    });
  }

  void _toggleSelectAll(bool selectAll) {
    if (_selectableDiaryCount == 0) {
      return;
    }

    setState(() {
      if (selectAll) {
        _selectedDiaryIds
          ..clear()
          ..addAll(
            _displayedDiaries
                .map((diary) => diary.id)
                .whereType<String>()
                .toList(),
          );
      } else {
        _selectedDiaryIds.clear();
      }
    });
  }

  Future<void> _confirmBulkDelete() async {
    final selectedCount = _selectedDiaryIds.length;

    if (selectedCount == 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('선택한 일기를 삭제할까요?'),
          content: Text(
            '총 ${selectedCount}개의 일기를 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: _isBulkDeleting
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: _isBulkDeleting
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteSelectedDiaries();
    }
  }

  Future<void> _deleteSelectedDiaries() async {
    final idsToDelete = List<String>.from(_selectedDiaryIds);

    if (idsToDelete.isEmpty) {
      return;
    }

    setState(() {
      _isBulkDeleting = true;
    });

    final List<String> deletedIds = [];
    final List<String> failedIds = [];

    for (final diaryId in idsToDelete) {
      final success = await DiaryApiService.instance.deleteDiary(diaryId);
      if (success) {
        deletedIds.add(diaryId);
      } else {
        failedIds.add(diaryId);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isBulkDeleting = false;

      if (deletedIds.isNotEmpty) {
        _allDiaries.removeWhere((diary) => deletedIds.contains(diary.id));
        _displayedDiaries
            .removeWhere((diary) => deletedIds.contains(diary.id));

        for (final diaryId in deletedIds) {
          _diaryImagesCache.remove(diaryId);
          _loadingImages.remove(diaryId);
          _categoryAssignments.remove(diaryId);
          _selectedDiaryIds.remove(diaryId);
        }
      }

      if (_selectedDiaryIds.isEmpty) {
        _selectionMode = false;
      }
    });

    final messenger = ScaffoldMessenger.of(context);

    if (deletedIds.isNotEmpty && failedIds.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('${deletedIds.length}개의 일기를 삭제했습니다.')),
      );
    } else if (deletedIds.isNotEmpty && failedIds.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${deletedIds.length}개의 일기를 삭제했습니다. ${failedIds.length}개의 일기는 삭제하지 못했습니다.',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('선택한 일기를 삭제하지 못했습니다. 다시 시도해 주세요.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
          if (!_selectionMode && _displayedDiaries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildBulkActionButton(),
              ),
            ),
          Expanded(
            child: _displayedDiaries.isEmpty && !_isLoading
                ? _buildEmptyState()
                : _buildDiaryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectionMode) ...[
            _buildSelectionControls(),
            const SizedBox(height: 12),
          ],
          _buildCategorySelector(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              const minSearchWidth = 160.0;
              final filterWidth = _filterButtonWidth;
              final available = constraints.maxWidth - filterWidth - gap;

              if (available >= minSearchWidth) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: available,
                      child: _buildSearchField(),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: filterWidth,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildFilterTrigger(),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildFilterTrigger(),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (_dateFilter == 'custom' &&
              _startDate != null &&
              _endDate != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_formatDate(_startDate!)} ~ ${_formatDate(_endDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTrigger() {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _openFilterSheet,
          icon: Icon(Icons.tune_rounded, color: iconColor, size: 24),
          tooltip: '필터',
          splashRadius: 22,
        ),
        if (_hasActiveFilters())
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  double get _filterButtonWidth => 44;

  Future<void> _openFilterSheet() async {
    String tempEmotion = _selectedEmotion;
    String tempDateFilter = _dateFilter;
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    String tempSort = _sortOrder;

    final result = await showModalBottomSheet<_FilterSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> selectEmotion() async {
              final selected = await _showOptionDialog(
                context: context,
                title: '감정별 보기',
                options: const [
                  _OptionItem(value: 'all', label: '모든 감정'),
                  _OptionItem(value: 'happy', label: '기쁨'),
                  _OptionItem(value: 'sad', label: '슬픔'),
                  _OptionItem(value: 'angry', label: '화남'),
                  _OptionItem(value: 'peaceful', label: '평온'),
                  _OptionItem(value: 'unrest', label: '불안'),
                ],
                selectedValue: tempEmotion,
              );
              if (selected != null) {
                setSheetState(() => tempEmotion = selected);
              }
            }

            Future<void> selectSort() async {
              final selected = await _showOptionDialog(
                context: context,
                title: '정렬 기준',
                options: const [
                  _OptionItem(value: 'desc', label: '최신순'),
                  _OptionItem(value: 'asc', label: '오래된순'),
                ],
                selectedValue: tempSort,
              );
              if (selected != null) {
                setSheetState(() => tempSort = selected);
              }
            }

            Future<void> selectDate() async {
              final selected = await _showOptionDialog(
                context: context,
                title: '기간 선택',
                options: const [
                  _OptionItem(value: 'all', label: '전체 기간'),
                  _OptionItem(value: 'today', label: '오늘'),
                  _OptionItem(value: 'week', label: '일주일'),
                  _OptionItem(value: 'month', label: '한 달'),
                  _OptionItem(value: 'custom', label: '기간 직접 선택'),
                ],
                selectedValue: tempDateFilter,
              );

              if (selected == null) {
                return;
              }

              if (selected == 'custom') {
                final range = await _pickDateRange(
                  start: tempStart,
                  end: tempEnd,
                );
                if (range != null) {
                  setSheetState(() {
                    tempDateFilter = 'custom';
                    tempStart = range.start;
                    tempEnd = range.end;
                  });
                }
              } else {
                setSheetState(() {
                  tempDateFilter = selected;
                  tempStart = null;
                  tempEnd = null;
                });
              }
            }

            void resetFilters() {
              setSheetState(() {
                tempEmotion = 'all';
                tempDateFilter = 'all';
                tempStart = null;
                tempEnd = null;
                tempSort = 'desc';
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 12,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '필터 설정',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _FilterTile(
                      icon: Icons.mood,
                      title: '감정별 보기',
                      subtitle: _emotionLabel(tempEmotion),
                      onTap: selectEmotion,
                    ),
                    _FilterTile(
                      icon: Icons.calendar_today,
                      title: '기간 선택',
                      subtitle:
                          _dateFilterLabel(tempDateFilter, tempStart, tempEnd),
                      onTap: selectDate,
                    ),
                    _FilterTile(
                      icon: Icons.sort,
                      title: '정렬 기준',
                      subtitle: _sortOrderLabel(tempSort),
                      onTap: selectSort,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: resetFilters,
                          child: const Text('필터 초기화'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              _FilterSheetResult(
                                emotion: tempEmotion,
                                dateFilter: tempDateFilter,
                                startDate: tempStart,
                                endDate: tempEnd,
                                sortOrder: tempSort,
                              ),
                            );
                          },
                          child: const Text('완료'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedEmotion = result.emotion;
        _dateFilter = result.dateFilter;
        _startDate = result.startDate;
        _endDate = result.endDate;
        _sortOrder = result.sortOrder;
      });
      _applyFilters();
    }
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    final label = _currentCategoryLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _isLoadingCategories ? null : _showCategorySelectorSheet,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          icon: const Icon(Icons.menu_book_outlined),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        if (_isLoadingCategories)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Widget _buildSelectionControls() {
    final theme = Theme.of(context);

    final chipColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final deleteWidth = 68.0;
        final cancelWidth = 68.0;
        final totalButtonWidth = deleteWidth + cancelWidth + spacing;
        final availableForChip = constraints.maxWidth - totalButtonWidth - spacing;

        final chip = Container(
          width: availableForChip.clamp(120.0, constraints.maxWidth - totalButtonWidth),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor.withOpacity(0.6)),
            color: _isAllVisibleSelected
                ? chipColor.withOpacity(0.12)
                : theme.colorScheme.surface,
          ),
          child: InkWell(
            onTap: _isBulkDeleting
                ? null
                : () => _toggleSelectAll(!_isAllVisibleSelected),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAllVisibleSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 18,
                  color: chipColor,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '전체 선택 ($_selectedCountText)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return Row(
          children: [
            Expanded(child: chip),
            const SizedBox(width: spacing),
            SizedBox(
              width: deleteWidth,
              height: 32,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 11),
                ),
                onPressed:
                    (!_hasSelection || _isBulkDeleting) ? null : _confirmBulkDelete,
                child: _isBulkDeleting
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Text('선택 삭제'),
              ),
            ),
            const SizedBox(width: spacing),
            SizedBox(
              width: cancelWidth,
              height: 32,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 11),
                ),
                onPressed: _isBulkDeleting ? null : _exitSelectionMode,
                child: const Text('선택 취소'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '제목이나 내용으로 검색하세요',
        prefixIcon: Icon(
          Icons.search,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.6),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.2,
          ),
        ),
        filled: true,
        fillColor: theme.cardColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      onChanged: (value) => _applyFilters(),
    );
  }

  Widget? _buildBulkActionButton() {
    if (_displayedDiaries.isEmpty && !_selectionMode) {
      return null;
    }

    if (_selectionMode) {
      return TextButton.icon(
        onPressed: _isBulkDeleting ? null : _exitSelectionMode,
        icon: const Icon(Icons.close, size: 18),
        label: const Text('선택 취소'),
      );
    }

    return OutlinedButton.icon(
      onPressed: _enterSelectionMode,
      icon: const Icon(Icons.check_box_outlined, size: 18),
      label: const Text('일괄 선택'),
    );
  }

  Widget _buildEmotionFilterButton() {
    final items = const [
      {'value': 'all', 'label': '모든 감정'},
      {'value': 'happy', 'label': '기쁨'},
      {'value': 'sad', 'label': '슬픔'},
      {'value': 'angry', 'label': '화남'},
      {'value': 'peaceful', 'label': '평온'},
      {'value': 'unrest', 'label': '불안'},
    ];

    return _buildFilterIconButton(
      icon: Icons.mood,
      label: _emotionLabel(),
      isActive: _selectedEmotion != 'all',
      items: items
          .map(
            (item) => PopupMenuItem<String>(
              value: item['value']!,
              child: Text(item['label']!),
            ),
          )
          .toList(),
      onSelected: (value) {
        setState(() {
          _selectedEmotion = value;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildDateFilterButton() {
    final items = const [
      {'value': 'all', 'label': '전체 기간'},
      {'value': 'today', 'label': '오늘'},
      {'value': 'week', 'label': '일주일'},
      {'value': 'month', 'label': '한달'},
      {'value': 'custom', 'label': '기간 선택'},
    ];

    return _buildFilterIconButton(
      icon: Icons.calendar_today,
      label: _dateFilterLabel(),
      isActive: _dateFilter != 'all' ||
          (_dateFilter == 'custom' && _startDate != null && _endDate != null),
      items: items
          .map(
            (item) => PopupMenuItem<String>(
              value: item['value']!,
              child: Text(item['label']!),
            ),
          )
          .toList(),
      onSelected: (value) => _handleDateFilterSelection(value),
    );
  }

  Widget _buildSortFilterButton() {
    final items = const [
      {'value': 'desc', 'label': '최신순'},
      {'value': 'asc', 'label': '오래된순'},
    ];

    return _buildFilterIconButton(
      icon: Icons.sort,
      label: _sortOrderLabel(),
      isActive: _sortOrder != 'desc',
      items: items
          .map(
            (item) => PopupMenuItem<String>(
              value: item['value']!,
              child: Text(item['label']!),
            ),
          )
          .toList(),
      onSelected: (value) {
        setState(() {
          _sortOrder = value;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildFilterIconButton({
    required IconData icon,
    required String label,
    required List<PopupMenuEntry<String>> items,
    required ValueChanged<String> onSelected,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final iconColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.7);

    return PopupMenuButton<String>(
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      itemBuilder: (context) => items,
      surfaceTintColor: theme.cardColor,
      shadowColor: Colors.transparent,
      tooltip: label,
      child: _FilterIconTile(
        icon: icon,
        label: label,
        isActive: isActive,
        iconColor: iconColor,
      ),
    );
  }

  String _emotionLabel([String? value]) {
    final target = value ?? _selectedEmotion;
    switch (target) {
      case 'happy':
        return '기쁨';
      case 'sad':
        return '슬픔';
      case 'angry':
        return '화남';
      case 'peaceful':
        return '평온';
      case 'unrest':
        return '불안';
      default:
        return '모든 감정';
    }
  }

  String _dateFilterLabel([String? value, DateTime? start, DateTime? end]) {
    final target = value ?? _dateFilter;
    final startDate = start ?? _startDate;
    final endDate = end ?? _endDate;

    if (target == 'custom') {
      if (startDate != null && endDate != null) {
        return '${_formatDate(startDate)} ~ ${_formatDate(endDate)}';
      }
      return '기간 선택';
    }

    switch (target) {
      case 'today':
        return '오늘';
      case 'week':
        return '일주일';
      case 'month':
        return '한달';
      default:
        return '전체 기간';
    }
  }

  String _sortOrderLabel([String? value]) {
    final target = value ?? _sortOrder;
    switch (target) {
      case 'asc':
        return '오래된순';
      default:
        return '최신순';
    }
  }

  Future<DateTimeRange?> _pickDateRange({
    DateTime? start,
    DateTime? end,
  }) async {
    final now = DateTime.now();
    final initialStart = start ?? now.subtract(const Duration(days: 6));
    final initialEnd = end ?? now;

    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: '기간을 선택하세요',
      saveText: '완료',
    );
  }

  Future<void> _handleDateFilterSelection(String value) async {
    if (value == 'custom') {
      final now = DateTime.now();
      final initialStart = _startDate ?? now.subtract(const Duration(days: 6));
      final initialEnd = _endDate ?? now;

      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 1),
        initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
        helpText: '기간을 선택하세요',
        saveText: '완료',
      );

      if (pickedRange != null) {
        setState(() {
          _dateFilter = 'custom';
          _startDate = pickedRange.start;
          _endDate = pickedRange.end;
        });
        _applyFilters();
      }
      return;
    }

    setState(() {
      _dateFilter = value;
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }

  String get _selectedCountText {
    final total = _selectableDiaryCount;
    final selectedCount = _selectedDiaryIds.length;
    return total > 0 ? '$selectedCount/$total' : '0/0';
  }

  String _currentCategoryLabel() {
    if (_selectedCategoryId == null) {
      return '전체 보기';
    }
    if (_selectedCategoryId == _defaultCategoryKey) {
      return '기본 다이어리';
    }
    final category = _categories.firstWhere(
      (element) => element.id == _selectedCategoryId,
      orElse: () => DiaryCategory(
        id: _selectedCategoryId!,
        name: '알 수 없는 카테고리',
        createdAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  Future<void> _showCategorySelectorSheet() async {
    if (_isLoadingCategories && _categories.isEmpty) {
      return;
    }

    final theme = Theme.of(context);
    final overlayItems = <_OverlayCategoryItem>[
      const _OverlayCategoryItem(id: null, label: '전체 보기', icon: Icons.menu_book_outlined),
      const _OverlayCategoryItem(
        id: _defaultCategoryKey,
        label: '기본 다이어리',
        icon: Icons.menu_book_outlined,
      ),
      ..._categories.map(
        (category) => _OverlayCategoryItem(
          id: category.id,
          label: category.name,
          icon: Icons.menu_book_outlined,
        ),
      ),
    ];

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카테고리 선택',
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: overlayItems.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.4),
                      ),
                      itemBuilder: (context, index) {
                        final item = overlayItems[index];
                        final isSelected = _selectedCategoryId == item.id ||
                            (_selectedCategoryId == null && item.id == null);

                        return ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                              : const Icon(Icons.keyboard_arrow_right),
                          onTap: () => Navigator.of(sheetContext).pop(item.id ?? _allCategoryValue),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _isLoadingCategories ? null : () => Navigator.of(sheetContext).pop(_createCategoryValue),
                      icon: const Icon(Icons.add),
                      label: const Text('새 다이어리 만들기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == _createCategoryValue) {
      await _createCategory();
      return;
    }

    if (result == _allCategoryValue) {
      _onCategorySelected(null);
      return;
    }

    _onCategorySelected(result);
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _selectedEmotion != 'all' ||
        _dateFilter != 'all' ||
        _sortOrder != 'desc';
  }

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    if (_searchController.text.isNotEmpty) {
      filterChips.add(
        _buildFilterChip('검색: "${_searchController.text}"', () {
          _searchController.clear();
          _applyFilters();
        }),
      );
    }

    if (_selectedEmotion != 'all') {
      filterChips.add(
        _buildFilterChip('감정: ${_emotionLabel()}', () {
          setState(() {
            _selectedEmotion = 'all';
          });
          _applyFilters();
        }),
      );
    }

    if (_dateFilter != 'all' ||
        (_dateFilter == 'custom' && _startDate != null && _endDate != null)) {
      final label = _dateFilterLabel();
      filterChips.add(
        _buildFilterChip('기간: $label', () {
          setState(() {
            _dateFilter = 'all';
            _startDate = null;
            _endDate = null;
          });
          _applyFilters();
        }),
      );
    }

    if (_sortOrder != 'desc') {
      filterChips.add(
        _buildFilterChip('정렬: ${_sortOrderLabel()}', () {
          setState(() {
            _sortOrder = 'desc';
          });
          _applyFilters();
        }),
      );
    }

    return Wrap(spacing: 8, children: filterChips);
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor:
          Theme.of(context).chipTheme.backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      deleteIconColor: context.colorScheme.primary,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어나 필터를 시도해보세요',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedEmotion = 'all';
                _dateFilter = 'all';
                _sortOrder = 'desc';
                _startDate = null;
                _endDate = null;
              });
              _applyFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
            ),
            child: const Text('필터 초기화'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _displayedDiaries.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _displayedDiaries.length) {
          return _buildLoadingIndicator();
        }
        return _buildDiaryCard(_displayedDiaries[index]);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary),
      ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry diary) {
    final diaryId = diary.id;
    final isSelected =
        diaryId != null && _selectedDiaryIds.contains(diaryId);
    final date = diary.diaryDate;
    final dateString = date != null
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : '날짜 미정';

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (_selectionMode) {
                _toggleDiarySelection(diaryId);
              } else if (diaryId != null) {
                context.go('/diary/$diaryId');
              }
            },
            onLongPress: () {
              if (!_selectionMode && diaryId != null) {
                _enterSelectionMode(diaryId);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 썸네일 이미지
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Stack(
                    children: [
                      _buildDiaryImage(diary),
                      // 감정 이모지
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: EmotionEmojiWidget(
                            emotion: diary.aiEmotion ??
                                diary.emotion ??
                                'peaceful',
                            size: 20,
                            imageScale: 1.3,
                          ),
                        ),
                      ),
                      // 날짜
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryText.withAlpha(180),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dateString,
                            style: TextStyle(
                              color: context.colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 카드 내용
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        diary.title ?? '제목 없음',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // 내용 또는 AI 생성 텍스트
                      Text(
                        diary.aiGeneratedText ?? diary.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // 키워드
                      diary.keywords.isNotEmpty
                          ? Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  diary.keywords.take(3).map((keyword) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                            .chipTheme
                                            .backgroundColor ??
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.colorScheme.primary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '#$keyword',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectionMode)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: Checkbox(
                value: isSelected,
                onChanged: _isBulkDeleting
                    ? null
                    : (value) => _toggleDiarySelection(diaryId),
              ),
            ),
          ),
      ],
    );
  }


  /// 다이어리 이미지 빌드 (첫 번째 이미지 표시)
  Widget _buildDiaryImage(DiaryEntry diary) {
    // 이미지 로드 (캐시되지 않은 경우)
    if (!_diaryImagesCache.containsKey(diary.id) &&
        !_loadingImages.contains(diary.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDiaryImages(diary.id);
      });
    }

    final images = _diaryImagesCache[diary.id];
    final isLoading = _loadingImages.contains(diary.id);

    if (isLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    if (images != null && images.isNotEmpty) {
      final firstImage = images.first;
      final imageUrl = firstImage.fullImageUrl;

      if (imageUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: context.borderSubtle,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.image,
                  size: 60,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              );
            },
          ),
        );
      }
    }

    // 기본 이미지 (이미지가 없는 경우)
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.image,
        size: 60,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}

class _OverlayCategoryItem {
  const _OverlayCategoryItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String? id;
  final String label;
  final IconData icon;
}

class _FilterIconTile extends StatelessWidget {
  const _FilterIconTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeBackground = theme.colorScheme.primary.withOpacity(0.1);
    final inactiveBackground =
        theme.colorScheme.surfaceVariant.withOpacity(0.4);

    return Container(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? activeBackground : inactiveBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, color: iconColor, size: 18),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        Divider(color: theme.colorScheme.outlineVariant, height: 1),
      ],
    );
  }
}

class _OptionItem {
  const _OptionItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _FilterSheetResult {
  const _FilterSheetResult({
    required this.emotion,
    required this.dateFilter,
    required this.startDate,
    required this.endDate,
    required this.sortOrder,
  });

  final String emotion;
  final String dateFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortOrder;
}

Future<String?> _showOptionDialog({
  required BuildContext context,
  required String title,
  required List<_OptionItem> options,
  required String selectedValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: options.map((option) {
              final isSelected = option.value == selectedValue;
              return RadioListTile<String>(
                value: option.value,
                groupValue: selectedValue,
                onChanged: (value) => Navigator.of(dialogContext).pop(value),
                title: Text(option.label),
                contentPadding: EdgeInsets.zero,
                dense: true,
                selected: isSelected,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
        ],
      );
    },
  );
}
