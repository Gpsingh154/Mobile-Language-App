import 'package:flutter/material.dart';
import '../../state/app_state_controller.dart';

class GalleryPickerSheet extends StatelessWidget {
  const GalleryPickerSheet({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  static final List<_GalleryItem> _items = [
    const _GalleryItem(
      title: 'Textbook Page (Linguistics)',
      subtitle: 'Multimodal language systems & acoustic models',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF3B82F6),
    ),
    const _GalleryItem(
      title: 'Earthen Water Pitcher (ਕੁੱਜਾ)',
      subtitle: 'Traditional Punjabi pottery & evaporative cooling',
      icon: Icons.filter_vintage_rounded,
      color: Color(0xFF10B981),
    ),
    const _GalleryItem(
      title: 'Cultural Heritage Signs',
      subtitle: 'Regional Gurmukhi script & terminology',
      icon: Icons.signpost_rounded,
      color: Color(0xFFF59E0B),
    ),
    const _GalleryItem(
      title: 'Classroom Vocabulary Board',
      subtitle: 'Grammar notes and syntax patterns',
      icon: Icons.dashboard_customize_rounded,
      color: Color(0xFFA855F7),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF131A26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.photo_library_rounded, size: 20, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              const Text(
                'Select Photo from Local Gallery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1x Static Frame',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulls isolated image payload into the On-Demand Vision Router without continuous camera rendering.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ..._items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.white12),
                ),
                tileColor: const Color(0xFF1A2230),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.selectGalleryPhoto(item.title);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GalleryItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _GalleryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
