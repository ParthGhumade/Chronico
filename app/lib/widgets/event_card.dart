import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
class ChronicoEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const ChronicoEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onMoreTap,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isGenerated = event.status == EventStatus.generated;
    final hasImage = event.attachedPhotos.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: ChronicoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronicoColors.outlineVariant, width: 1),
        image: hasImage
            ? DecorationImage(
                image: ResizeImage(
                  (kIsWeb || event.attachedPhotos.first.startsWith('http') || event.attachedPhotos.first.startsWith('blob:'))
                      ? NetworkImage(event.attachedPhotos.first) as ImageProvider
                      : FileImage(File(event.attachedPhotos.first)),
                  width: 400, // Acts as a performance-friendly thumbnail
                ),
                fit: BoxFit.cover,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
            if (!hasImage)
              Center(
                child: Icon(
                  Icons.event_note_outlined,
                  size: 48,
                  color: isGenerated
                      ? ChronicoColors.tertiary.withOpacity(0.5)
                      : ChronicoColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isGenerated
                          ? ChronicoColors.primaryContainer.withOpacity(0.9)
                          : ChronicoColors.surfaceContainerHigh.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isGenerated ? 'Generated' : 'Draft',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isGenerated
                            ? ChronicoColors.primary
                            : ChronicoColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.date),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
