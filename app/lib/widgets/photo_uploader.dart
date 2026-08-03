import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
class ChronicoPhotoUploader extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;

  const ChronicoPhotoUploader({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        final updated = List<String>.from(photos)..addAll(images.map((e) => e.path));
        onChanged(updated);
      }
    } catch (e) {
      // Ignored for now
    }
  }

  void _removePhoto(int index) {
    final updated = List<String>.from(photos)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronicoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChronicoColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Photos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ChronicoColors.onSurface,
                  ),
                ),
              ),
              Text(
                '${photos.length} attached',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: ChronicoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: photos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Upload button
                return InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ChronicoColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ChronicoColors.outlineVariant,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: ChronicoColors.primary, size: 24),
                        SizedBox(height: 4),
                        Text(
                          'Upload',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ChronicoColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final photoIndex = index - 1;
              final photoUrl = photos[photoIndex];

              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: (kIsWeb || photoUrl.startsWith('http') || photoUrl.startsWith('blob:'))
                            ? NetworkImage(photoUrl) as ImageProvider
                            : FileImage(File(photoUrl)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _removePhoto(photoIndex),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
