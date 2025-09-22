import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

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
  List<Map<String, dynamic>> _filteredDiaries = [];
  List<Map<String, dynamic>> _displayedDiaries = [];
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  // 더미 데이터 (10개)
  final List<Map<String, dynamic>> _allDiaries = [
    {
      'id': 1,
      'title': '햇살 좋은 하루',
      'content': '오늘은 정말 좋은 하루였다. 따뜻한 햇살이 마음까지 따뜻하게 만들어주었고, 친구들과의 만남도 즐거웠다.',
      'ai_generated_text':
          '따스한 햇살처럼 당신의 마음도 밝게 빛나고 있군요. 이런 순간들이 모여 아름다운 추억이 됩니다.',
      'emotion': 'happy',
      'date': DateTime(2024, 1, 20),
      'keywords': ['햇살', '친구', '즐거움', '따뜻함'],
      'thumbnail': 'https://picsum.photos/400/250?random=1',
    },
    {
      'id': 2,
      'title': '비 오는 날의 감성',
      'content': '창밖에 내리는 비를 보며 깊은 생각에 잠겼다. 때로는 이런 고요한 시간이 필요한 것 같다.',
      'ai_generated_text':
          '비 내리는 소리가 마음의 소음을 씻어내 주는군요. 고요 속에서 진정한 나를 만날 수 있습니다.',
      'emotion': 'peaceful',
      'date': DateTime(2024, 1, 19),
      'keywords': ['비', '고요', '사색', '평온'],
      'thumbnail': 'https://picsum.photos/400/250?random=2',
    },
    {
      'id': 3,
      'title': '힘든 하루의 끝',
      'content': '오늘은 많은 일들이 겹쳐서 힘든 하루였다. 하지만 이런 날들도 지나간다는 것을 안다.',
      'ai_generated_text': '어둠이 짙을수록 새벽은 더욱 밝게 다가옵니다. 지금의 어려움도 성장의 밑거름이 될 거예요.',
      'emotion': 'sad',
      'date': DateTime(2024, 1, 18),
      'keywords': ['힘듦', '인내', '희망', '성장'],
      'thumbnail': 'https://picsum.photos/400/250?random=3',
    },
    {
      'id': 4,
      'title': '화가 났던 순간',
      'content': '오늘은 정말 화가 났다. 불공평한 일들이 계속 일어나는 것 같아서 속상했다.',
      'ai_generated_text':
          '분노도 당신의 소중한 감정입니다. 이 감정을 통해 진정 원하는 것이 무엇인지 알 수 있어요.',
      'emotion': 'angry',
      'date': DateTime(2024, 1, 17),
      'keywords': ['분노', '불공평', '감정', '성찰'],
      'thumbnail': 'https://picsum.photos/400/250?random=4',
    },
    {
      'id': 5,
      'title': '불안한 마음',
      'content': '내일 중요한 발표가 있어서 밤새 잠이 오지 않았다. 걱정이 너무 많다.',
      'ai_generated_text':
          '불안은 당신이 그만큼 소중히 여기는 것이 있다는 증거입니다. 당신은 충분히 잘 해낼 거예요.',
      'emotion': 'anxious',
      'date': DateTime(2024, 1, 16),
      'keywords': ['불안', '발표', '걱정', '도전'],
      'thumbnail': 'https://picsum.photos/400/250?random=5',
    },
    {
      'id': 6,
      'title': '가족과의 시간',
      'content': '오랜만에 가족들과 함께 시간을 보냈다. 역시 가족만큼 소중한 것은 없는 것 같다.',
      'ai_generated_text': '가족의 사랑은 세상에서 가장 따뜻한 품입니다. 이런 순간들을 소중히 간직하세요.',
      'emotion': 'happy',
      'date': DateTime(2024, 1, 15),
      'keywords': ['가족', '사랑', '소중함', '행복'],
      'thumbnail': 'https://picsum.photos/400/250?random=6',
    },
    {
      'id': 7,
      'title': '새로운 도전',
      'content': '새로운 프로젝트를 시작했다. 두렵기도 하지만 설레는 마음이 더 크다.',
      'ai_generated_text': '새로운 시작은 언제나 용기가 필요합니다. 당신의 도전 정신이 빛을 발할 때입니다.',
      'emotion': 'peaceful',
      'date': DateTime(2024, 1, 14),
      'keywords': ['도전', '시작', '용기', '설렘'],
      'thumbnail': 'https://picsum.photos/400/250?random=7',
    },
    {
      'id': 8,
      'title': '외로운 밤',
      'content': '혼자 있는 시간이 길어질수록 외로움이 밀려온다. 누군가와 대화하고 싶다.',
      'ai_generated_text':
          '외로움을 느끼는 것은 인간다운 감정입니다. 이 시간도 자신과 깊이 만나는 소중한 순간이에요.',
      'emotion': 'sad',
      'date': DateTime(2024, 1, 13),
      'keywords': ['외로움', '고독', '성찰', '인간미'],
      'thumbnail': 'https://picsum.photos/400/250?random=8',
    },
    {
      'id': 9,
      'title': '운동 후 상쾌함',
      'content': '오랜만에 운동을 했더니 몸도 마음도 개운하다. 역시 건강이 최고다.',
      'ai_generated_text': '건강한 몸에 건강한 마음이 깃듭니다. 자신을 돌보는 당신의 모습이 아름다워요.',
      'emotion': 'happy',
      'date': DateTime(2024, 1, 12),
      'keywords': ['운동', '건강', '상쾌함', '자기관리'],
      'thumbnail': 'https://picsum.photos/400/250?random=9',
    },
    {
      'id': 10,
      'title': '미래에 대한 걱정',
      'content': '앞으로 어떻게 살아야 할지 모르겠다. 계획은 있지만 불확실한 미래가 무섭다.',
      'ai_generated_text': '미래는 불확실하지만 당신에게는 지금 이 순간이 있습니다. 한 걸음씩 나아가면 됩니다.',
      'emotion': 'anxious',
      'date': DateTime(2024, 1, 11),
      'keywords': ['미래', '불안', '계획', '걱정'],
      'thumbnail': 'https://picsum.photos/400/250?random=10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredDiaries = List.from(_allDiaries);
    _loadMoreItems();
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

  void _loadMoreItems() {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    // 무한스크롤 시뮬레이션
    Future.delayed(const Duration(milliseconds: 500), () {
      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = (startIndex + _itemsPerPage).clamp(
        0,
        _filteredDiaries.length,
      );

      if (startIndex < _filteredDiaries.length) {
        final newItems = _filteredDiaries.sublist(startIndex, endIndex);
        setState(() {
          _displayedDiaries.addAll(newItems);
          _currentPage++;
          _hasMore = endIndex < _filteredDiaries.length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allDiaries);

    // 검색어 필터
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((diary) {
        return diary['title'].toString().toLowerCase().contains(searchTerm) ||
            diary['content'].toString().toLowerCase().contains(searchTerm);
      }).toList();
    }

    // 감정 필터
    if (_selectedEmotion != 'all') {
      filtered = filtered
          .where((diary) => diary['emotion'] == _selectedEmotion)
          .toList();
    }

    // 날짜 필터
    if (_dateFilter != 'all') {
      final now = DateTime.now();
      DateTime? filterDate;

      switch (_dateFilter) {
        case 'today':
          filterDate = DateTime(now.year, now.month, now.day);
          filtered = filtered.where((diary) {
            final diaryDate = diary['date'] as DateTime;
            return diaryDate.isAfter(filterDate!) ||
                diaryDate.isAtSameMomentAs(filterDate);
          }).toList();
          break;
        case 'week':
          filterDate = now.subtract(const Duration(days: 7));
          filtered = filtered.where((diary) {
            final diaryDate = diary['date'] as DateTime;
            return diaryDate.isAfter(filterDate!);
          }).toList();
          break;
        case 'month':
          filterDate = DateTime(now.year, now.month - 1, now.day);
          filtered = filtered.where((diary) {
            final diaryDate = diary['date'] as DateTime;
            return diaryDate.isAfter(filterDate!);
          }).toList();
          break;
        case 'custom':
          if (_startDate != null && _endDate != null) {
            filtered = filtered.where((diary) {
              final diaryDate = diary['date'] as DateTime;
              return diaryDate.isAfter(_startDate!) &&
                  diaryDate.isBefore(_endDate!.add(const Duration(days: 1)));
            }).toList();
          }
          break;
      }
    }

    // 정렬
    filtered.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return _sortOrder == 'desc'
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });

    setState(() {
      _filteredDiaries = filtered;
      _displayedDiaries.clear();
      _currentPage = 0;
      _hasMore = true;
      _loadMoreItems();
    });
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
                        {'value': 'anxious', 'label': '😨 불안'},
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
        'anxious': '😨 불안',
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

  Widget _buildDiaryCard(Map<String, dynamic> diary) {
    final date = diary['date'] as DateTime;
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
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: Colors.grey[300],
                  ),
                  child: const Icon(Icons.image, size: 60, color: Colors.grey),
                ),
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
                      _getEmotionEmoji(diary['emotion']),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  diary['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // 내용
                Text(
                  diary['content'],
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (diary['keywords'] as List<String>).map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB2C5B8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFB2C5B8).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '#$keyword',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB2C5B8),
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
      case 'anxious':
        return '😨';
      default:
        return '😊';
    }
  }
}
