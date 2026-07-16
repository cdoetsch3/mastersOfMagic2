import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../home_shell.dart';

/// Phase 1: an empty inventory with the crafting verbs previewed. The item
/// catalog, crafting, and salvage arrive in Phase 2.
class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(title: 'Inventory'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            children: [
              GamePanel(
                child: Column(
                  children: const [
                    Icon(Icons.backpack, color: AppColors.textFaint, size: 40),
                    SizedBox(height: 10),
                    Text('Your pack is empty',
                        style:
                            TextStyle(color: AppColors.text, fontSize: 15)),
                    SizedBox(height: 4),
                    Text(
                        'Loot, materials, and equipment drop from adventures '
                        'once the item system arrives.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textDim, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Crafting (coming in Phase 2)'),
              const _CraftVerb(
                icon: Icons.change_circle,
                title: 'Transmute',
                subtitle: 'Refine raw materials (cure hide → leather)',
              ),
              const _CraftVerb(
                icon: Icons.handyman,
                title: 'Craft',
                subtitle: 'Combine goods into equipment (cloth → robe)',
              ),
              const _CraftVerb(
                icon: Icons.recycling,
                title: 'Salvage',
                subtitle: 'Break equipment back into components',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CraftVerb extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CraftVerb({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: 0.55,
        child: GamePanel(
          child: Row(
            children: [
              Icon(icon, color: AppColors.teal, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textDim, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.lock, color: AppColors.textFaint, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
