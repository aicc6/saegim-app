import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/models/diary_image_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

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
  List<DiaryEntry> _filteredDiaries = [];
  List<DiaryEntry> _displayedDiaries = [];
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  // 다이어리별 이미지 캐시
  final Map<String, List<DiaryImage>> _diaryImagesCache = {};
  final Set<String> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
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

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _displayedDiaries.clear();
    });

    await _loadDiariesFromAPI();
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
            // 첫 페이지인 경우 기존 데이터 클리어
            _displayedDiaries.clear();
            _filteredDiaries.clear();
          }

          if (diaries != null && diaries.isNotEmpty) {
            _displayedDiaries.addAll(diaries);
            _filteredDiaries.addAll(diaries);

            // 백엔드에서 반환된 데이터가 요청한 페이지 크기보다 적으면 더 이상 데이터가 없음
            _hasMore = diaries.length >= _itemsPerPage;

            AppLogger.info(
              'Loaded ${diaries.length} diaries for page $_currentPage',
              'DiaryListPage',
            );
          } else {
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

  /// 필터 적용 (새로운 검색)
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _displayedDiaries.clear();
      _filteredDiaries.clear();
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
          // 검색 및 필터 섹션
          _buildFilterSection(),
          // 다이어리 목록
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
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // 검색창
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '제목이나 내용으로 검색하세요',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFB2C5B8)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFB2C5B8),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
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

  Widget _buildFilterDropdown({
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white,
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
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      dropdownColor: Colors.white,
      isExpanded: true, // 중요: 드롭다운이 전체 너비를 사용하도록 설정
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('기간 선택', style: TextStyle(fontWeight: FontWeight.w500)),
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
      backgroundColor: const Color(0xFFF0F4F1),
      deleteIconColor: const Color(0xFFB2C5B8),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text('다른 검색어나 필터를 시도해보세요', style: TextStyle(color: Colors.grey[500])),
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
              backgroundColor: const Color(0xFFB2C5B8),
              foregroundColor: Colors.white,
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
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB2C5B8)),
      ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry diary) {
    final date = diary.diaryDate;
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                color: Colors.grey[200],
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
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        diary.emotionEmoji,
                        style: const TextStyle(fontSize: 20),
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
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dateString,
                        style: const TextStyle(
                          color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                      color: Colors.grey[600],
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
                            color: const Color(0xFFF0F4F1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFB2C5B8),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#$keyword',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4A7C59),
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
        color: Colors.grey[300],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB2C5B8)),
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
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFB2C5B8),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
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
      color: Colors.grey[300],
      child: const Icon(Icons.image, size: 60, color: Colors.grey),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      case 'peaceful':
        return '😌';
      case 'unrest':
      case 'anxious':
        return '😨';
      default:
        return '😊';
    }
  }
}
