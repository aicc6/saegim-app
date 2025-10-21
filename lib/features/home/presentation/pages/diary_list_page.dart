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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySelector(),
          const SizedBox(height: 16),
          // 검색창
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '제목이나 내용으로 검색하세요',
              prefixIcon: Icon(
                Icons.search,
                color: context.colorScheme.primary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (value) => _applyFilters(),
          ),
          const SizedBox(height: 12),

          // 필터 옵션들 - 세로 배치로 변경
          Column(
            children: [
              // 첫 번째 줄: 감정 필터와 날짜 필터
              Row(
                children: [
                  // 감정 필터
                  Expanded(
                    child: _buildFilterDropdown(
                      icon: Icons.mood,
                      value: _selectedEmotion,
                      items: const [
                        {'value': 'all', 'label': '모든 감정'},
                        {'value': 'happy', 'label': '😊 기쁨'},
                        {'value': 'sad', 'label': '😢 슬픔'},
                        {'value': 'angry', 'label': '😡 화남'},
                        {'value': 'peaceful', 'label': '😌 평온'},
                        {'value': 'unrest', 'label': '😨 불안'},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEmotion = value!;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 날짜 필터
                  Expanded(
                    child: _buildFilterDropdown(
                      icon: Icons.calendar_today,
                      value: _dateFilter,
                      items: const [
                        {'value': 'all', 'label': '전체 기간'},
                        {'value': 'today', 'label': '오늘'},
                        {'value': 'week', 'label': '일주일'},
                        {'value': 'month', 'label': '한달'},
                        {'value': 'custom', 'label': '기간 선택'},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _dateFilter = value!;
                          if (value != 'custom') {
                            _startDate = null;
                            _endDate = null;
                          }
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 두 번째 줄: 정렬 옵션
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      icon: Icons.sort,
                      value: _sortOrder,
                      items: const [
                        {'value': 'desc', 'label': '최신순'},
                        {'value': 'asc', 'label': '오래된순'},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortOrder = value!;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  // 오른쪽 공간 확보
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),

          // 커스텀 날짜 선택
          if (_dateFilter == 'custom') ...[
            const SizedBox(height: 12),
            _buildDateRangeSelector(),
          ],

          // 적용된 필터 표시
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
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

  Widget _buildFilterDropdown({
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        isDense: true,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(
            item['label']!,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      dropdownColor: Theme.of(context).cardColor,
      isExpanded: true, // 중요: 드롭다운이 전체 너비를 사용하도록 설정
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기간 선택',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                      _applyFilters();
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _startDate != null
                        ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                        : '시작일',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const Text(' ~ '),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                      _applyFilters();
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _endDate != null
                        ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                        : '종료일',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.clear, size: 18),
                tooltip: '초기화',
              ),
            ],
          ),
        ],
      ),
    );
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
      final emotionLabels = {
        'happy': '😊 기쁨',
        'sad': '😢 슬픔',
        'angry': '😡 화남',
        'peaceful': '😌 평온',
        'unrest': '😨 불안',
      };
      filterChips.add(
        _buildFilterChip('감정: ${emotionLabels[_selectedEmotion]}', () {
          setState(() {
            _selectedEmotion = 'all';
          });
          _applyFilters();
        }),
      );
    }

    if (_dateFilter != 'all') {
      final dateLabels = {
        'today': '오늘',
        'week': '일주일',
        'month': '한달',
        'custom': '기간 선택',
      };
      filterChips.add(
        _buildFilterChip('기간: ${dateLabels[_dateFilter]}', () {
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
        _buildFilterChip('정렬: 오래된순', () {
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
    final date = diary.diaryDate;
    final dateString = date != null
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : '날짜 미정';

    return Container(
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
          // 다이어리 상세 페이지로 이동
          context.go('/diary/${diary.id}');
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: EmotionEmojiWidget(
                        emotion: diary.aiEmotion ?? diary.emotion ?? 'peaceful',
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 키워드
                  if (diary.keywords.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: diary.keywords.take(3).map((keyword) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).chipTheme.backgroundColor ??
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
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
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
