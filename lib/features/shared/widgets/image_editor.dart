import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../create/createid.dart';

class ImageEditor extends StatefulWidget {
  final List<ImageInfo> images;
  final Function(List<ImageInfo>) onImagesChanged;
  final bool isEditing;
  final String? entryId;
  final Dio dio;
  final Function(String) onImageDeleted;

  const ImageEditor({
    super.key,
    required this.images,
    required this.onImagesChanged,
    required this.isEditing,
    required this.dio,
    required this.onImageDeleted,
    this.entryId,
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  final ImagePicker _picker = ImagePicker();
  bool _showOptionsModal = false;

  Future<void> _handleLoadExistingImages() async {
    if (widget.entryId == null) return;

    try {
      final response = await widget.dio.get(
        '/api/diary/${widget.entryId}/images',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<ImageInfo> existingImages = (response.data['data'] as List)
            .map((img) => ImageInfo.fromJson(img))
            .toList();

        widget.onImagesChanged(existingImages);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기존 이미지를 성공적으로 불러왔습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기존 이미지 조회에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUploadNewImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (widget.entryId == null) {
        // 새로운 다이어리 생성 시
        final newImage = ImageInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: image.path,
          mimeType: 'image/jpeg',
        );
        widget.onImagesChanged([...widget.images, newImage]);
      } else {
        // 기존 다이어리 수정 시
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(image.path),
          'diary_id': widget.entryId,
        });

        final response = await widget.dio.post(
          '/api/diary/${widget.entryId}/upload-image',
          data: formData,
        );

        if (response.statusCode == 200 && response.data != null) {
          final newImage = ImageInfo.fromJson(response.data['data']);
          widget.onImagesChanged([...widget.images, newImage]);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지가 성공적으로 업로드되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('이미지: ', style: TextStyle(fontWeight: FontWeight.bold)),
            if (widget.isEditing)
              ElevatedButton(
                onPressed: () => setState(() => _showOptionsModal = true),
                child: const Text('사진 불러오기'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: image.thumbnailPath != null
                          ? Image.network(
                              '${widget.dio.options.baseUrl}/api/public/image-proxy?url=${Uri.encodeComponent(image.thumbnailPath!)}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 40),
                            )
                          : Image.network(
                              image.filePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 40),
                            ),
                    ),
                  ),
                  if (widget.isEditing)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () {
                          widget.onImageDeleted(image.id);
                          widget.onImagesChanged(
                            widget.images
                                .where((img) => img.id != image.id)
                                .toList(),
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        else if (widget.isEditing)
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: const Center(
              child: Text(
                '기존 이미지를 불러와주세요',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        if (_showOptionsModal)
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
                      '이미지 불러오기 옵션',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.entryId != null)
                      ListTile(
                        leading: const Text(
                          '🔄',
                          style: TextStyle(fontSize: 24),
                        ),
                        title: const Text('기존 이미지 불러오기'),
                        subtitle: const Text(
                          '데이터베이스에서 저장된 이미지\n삭제된 이미지도 복원됩니다',
                        ),
                        onTap: () {
                          _handleLoadExistingImages();
                          setState(() => _showOptionsModal = false);
                        },
                      ),
                    if (widget.entryId != null) const Divider(),
                    ListTile(
                      leading: const Text('📁', style: TextStyle(fontSize: 24)),
                      title: const Text('새 이미지 업로드'),
                      subtitle: const Text('로컬에서 새 이미지 선택'),
                      onTap: () {
                        _handleUploadNewImage();
                        setState(() => _showOptionsModal = false);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showOptionsModal = false),
                      child: const Text('취소'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
