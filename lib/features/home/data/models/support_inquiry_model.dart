/// 고객센터 문의 요청 모델
class SupportInquiryRequest {
  final String title;
  final String content;
  final bool imageAttached;
  final String? imageData;
  final String? imageFilename;
  final String? imageType;

  const SupportInquiryRequest({
    required this.title,
    required this.content,
    this.imageAttached = false,
    this.imageData,
    this.imageFilename,
    this.imageType,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'image_attached': imageAttached,
      if (imageData != null) 'image_data': imageData,
      if (imageFilename != null) 'image_filename': imageFilename,
      if (imageType != null) 'image_type': imageType,
    };
  }
}

/// 고객센터 문의 응답 모델
class SupportInquiryResponse {
  final String message;
  final String inquiryId;
  final String createdAt;

  const SupportInquiryResponse({
    required this.message,
    required this.inquiryId,
    required this.createdAt,
  });

  factory SupportInquiryResponse.fromJson(Map<String, dynamic> json) {
    return SupportInquiryResponse(
      message: json['message'],
      inquiryId: json['inquiry_id'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'inquiry_id': inquiryId,
      'created_at': createdAt,
    };
  }
}
