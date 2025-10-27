import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/home/data/models/diary_category_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 다이어리 카테고리 API 서비스
class DiaryCategoryService {
  DiaryCategoryService._();

  static final DiaryCategoryService instance = DiaryCategoryService._();

  final Dio _dio = DioClient.instance.dio;

  static const _recentKey = 'diary_category_recent';
  static const _recentLimit = 5;

  List<DiaryCategory>? _cachedCategories;

  /// 카테고리 목록 조회 (캐시 사용)
  Future<List<DiaryCategory>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final response = await _dio.get('/api/categories');
      if (response.statusCode == 200) {
        final data = response.data;
        final rawCategories =
            data is Map<String, dynamic> && data['data'] is List<dynamic>
                ? data['data'] as List<dynamic>
                : const [];

        final categories = rawCategories
            .whereType<Map<String, dynamic>>()
            .map(DiaryCategory.fromApiJson)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _cachedCategories = categories;
        return categories;
      }

      throw Exception('카테고리 목록을 불러오지 못했습니다.');
    } on DioException catch (dioError) {
      AppLogger.error(
        'Failed to load diary categories',
        tag: 'DiaryCategoryService',
        error: dioError,
      );
      throw Exception('카테고리를 불러오는 중 오류가 발생했습니다.');
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading diary categories',
        tag: 'DiaryCategoryService',
        error: e,
      );
      throw Exception('카테고리를 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 카테고리 생성
  Future<DiaryCategory> createCategory(String name) async {
    try {
      final response = await _dio.post('/api/categories', data: {'name': name});
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        final rawCategory =
            data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
                ? data['data'] as Map<String, dynamic>
                : null;

        if (rawCategory == null) {
          throw Exception('카테고리 정보를 확인할 수 없습니다.');
        }

        final category = DiaryCategory.fromApiJson(rawCategory);
        _updateCacheWith(category);
        await _addRecentCategory(category.id);
        return category;
      }

      throw Exception('카테고리를 생성하지 못했습니다.');
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 422) {
        throw Exception('카테고리 이름을 확인해주세요.');
      }

      AppLogger.error(
        'Failed to create diary category',
        tag: 'DiaryCategoryService',
        error: dioError,
      );
      throw Exception('카테고리를 생성하지 못했습니다.');
    } catch (e) {
      AppLogger.error(
        'Unexpected error creating diary category',
        tag: 'DiaryCategoryService',
        error: e,
      );
      throw Exception('카테고리를 생성하지 못했습니다.');
    }
  }

  /// 카테고리 이름 수정
  Future<DiaryCategory> renameCategory(String categoryId, String newName) async {
    try {
      final response =
          await _dio.patch('/api/categories/$categoryId', data: {'name': newName});
      if (response.statusCode == 200) {
        final data = response.data;
        final rawCategory =
            data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
                ? data['data'] as Map<String, dynamic>
                : null;

        if (rawCategory == null) {
          throw Exception('카테고리 정보를 확인할 수 없습니다.');
        }

        final category = DiaryCategory.fromApiJson(rawCategory);
        _updateCacheWith(category);
        return category;
      }

      throw Exception('카테고리를 수정하지 못했습니다.');
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 404) {
        throw Exception('존재하지 않는 카테고리입니다.');
      }

      AppLogger.error(
        'Failed to rename diary category',
        tag: 'DiaryCategoryService',
        error: dioError,
      );
      throw Exception('카테고리를 수정하지 못했습니다.');
    } catch (e) {
      AppLogger.error(
        'Unexpected error renaming diary category',
        tag: 'DiaryCategoryService',
        error: e,
      );
      throw Exception('카테고리를 수정하지 못했습니다.');
    }
  }

  /// 카테고리 삭제
  Future<void> deleteCategory(String categoryId) async {
    try {
      final response = await _dio.delete('/api/categories/$categoryId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _cachedCategories =
            _cachedCategories?.where((category) => category.id != categoryId).toList();
        await _removeRecentCategory(categoryId);
        return;
      }

      throw Exception('카테고리를 삭제하지 못했습니다.');
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 404) {
        throw Exception('이미 삭제된 카테고리입니다.');
      }

      AppLogger.error(
        'Failed to delete diary category',
        tag: 'DiaryCategoryService',
        error: dioError,
      );
      throw Exception('카테고리를 삭제하지 못했습니다.');
    } catch (e) {
      AppLogger.error(
        'Unexpected error deleting diary category',
        tag: 'DiaryCategoryService',
        error: e,
      );
      throw Exception('카테고리를 삭제하지 못했습니다.');
    }
  }

  /// 최근 사용한 카테고리 ID 리스트
  Future<List<String>> getRecentCategoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? const [];
  }

  Future<void> _addRecentCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(prefs.getStringList(_recentKey) ?? []);

    current.remove(categoryId);
    current.insert(0, categoryId);

    if (current.length > _recentLimit) {
      current.removeRange(_recentLimit, current.length);
    }

    await prefs.setStringList(_recentKey, current);
  }

  Future<void> _removeRecentCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(prefs.getStringList(_recentKey) ?? []);
    current.remove(categoryId);
    await prefs.setStringList(_recentKey, current);
  }

  void _updateCacheWith(DiaryCategory category) {
    final current = _cachedCategories ?? const <DiaryCategory>[];
    _cachedCategories = (current.where((item) => item.id != category.id).toList()
          ..add(category))
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
