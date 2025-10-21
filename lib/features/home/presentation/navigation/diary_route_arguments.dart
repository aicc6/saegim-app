import 'package:saegim/features/calendar/data/models/diary_model.dart';

/// 다이어리 라우트에서 사용하는 전달 인자 모음
class DiaryDetailRouteArguments {
  const DiaryDetailRouteArguments({
    this.tempEntry,
    this.startInEditMode,
    this.initialCategoryId,
  });

  final DiaryEntry? tempEntry;
  final bool? startInEditMode;
  final String? initialCategoryId;
}
