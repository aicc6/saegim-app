/// 감정별 이모티콘 설정
///
/// 사용자가 선택할 수 있는 다양한 이모티콘 스타일을 정의합니다.
/// 텍스트 이모지와 이미지 이모지를 모두 지원합니다.
class EmotionEmojiConfig {
  // 이모티콘 스타일 타입
  static const String styleDefault = 'default';
  static const String styleCute = 'cute';
  static const String styleMinimal = 'minimal';
  static const String styleColored = 'colored';
  static const String styleImage = 'image'; // PNG 이미지 스타일

  // 사용 가능한 모든 스타일
  static const List<String> availableStyles = [
    styleDefault,
    styleCute,
    styleMinimal,
    styleColored,
    styleImage,
  ];

  // 스타일별 한글 이름
  static const Map<String, String> styleNames = {
    styleDefault: '기본',
    styleCute: '귀여운',
    styleMinimal: '심플',
    styleColored: '컬러풀',
    styleImage: '이미지',
  };

  // 감정별 이모티콘 맵핑 (스타일별)
  static const Map<String, Map<String, String>> emojiStyles = {
    // 기본 스타일
    styleDefault: {
      'happy': '😊',
      'sad': '😢',
      'angry': '😠',
      'peaceful': '😌',
      'unrest': '😰',
    },

    // 귀여운 스타일
    styleCute: {
      'happy': '🥰',
      'sad': '🥺',
      'angry': '😤',
      'peaceful': '😇',
      'unrest': '😥',
    },

    // 심플 스타일
    styleMinimal: {
      'happy': '🙂',
      'sad': '🙁',
      'angry': '😑',
      'peaceful': '😐',
      'unrest': '😶',
    },

    // 컬러풀 스타일
    styleColored: {
      'happy': '💛',
      'sad': '💙',
      'angry': '❤️',
      'peaceful': '💚',
      'unrest': '🧡',
    },

    // 이미지 스타일 (PNG 경로)
    styleImage: {
      'happy': 'assets/emoji/emoji_happy.png',
      'sad': 'assets/emoji/emoji_sad.png',
      'angry': 'assets/emoji/emoji_angry.png',
      'peaceful': 'assets/emoji/emoji_original.png',
      'unrest': 'assets/emoji/emoji_1_1.png',
    },
  };

  /// 특정 스타일의 특정 감정 이모티콘 가져오기
  ///
  /// [emotion]: 감정 타입 (happy, sad, angry, peaceful, unrest)
  /// [style]: 이모티콘 스타일 (기본값: default)
  static String getEmoji(String emotion, {String style = styleDefault}) {
    final normalizedEmotion = _normalizeEmotion(emotion);
    return emojiStyles[style]?[normalizedEmotion] ??
        emojiStyles[styleDefault]?[normalizedEmotion] ??
        '😐';
  }

  /// 감정 이름 정규화 (한글 → 영어)
  static String _normalizeEmotion(String emotion) {
    final emotionMap = {
      '행복': 'happy',
      '기쁨': 'happy',
      '슬픔': 'sad',
      '분노': 'angry',
      '화남': 'angry',
      '평온': 'peaceful',
      '불안': 'unrest',
      'happy': 'happy',
      'sad': 'sad',
      'angry': 'angry',
      'peaceful': 'peaceful',
      'unrest': 'unrest',
      'anxious': 'unrest',
    };

    return emotionMap[emotion.toLowerCase()] ?? emotion.toLowerCase();
  }

  /// 스타일 이름 가져오기
  static String getStyleName(String style) {
    return styleNames[style] ?? '알 수 없음';
  }

  /// 특정 스타일의 모든 이모티콘 가져오기
  static Map<String, String> getStyleEmojis(String style) {
    return emojiStyles[style] ?? emojiStyles[styleDefault]!;
  }

  /// 이모지가 이미지 경로인지 확인
  ///
  /// [emojiOrPath]: 이모지 문자열 또는 이미지 경로
  /// 반환: 이미지 경로이면 true, 텍스트 이모지이면 false
  static bool isImagePath(String emojiOrPath) {
    return emojiOrPath.startsWith('assets/') && emojiOrPath.endsWith('.png');
  }

  /// 특정 스타일이 이미지 스타일인지 확인
  static bool isImageStyle(String style) {
    return style == styleImage;
  }
}
