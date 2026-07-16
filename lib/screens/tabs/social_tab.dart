import 'package:flutter/material.dart';

import '../../game/auth_service.dart';
import '../../ui/app_theme.dart';
import '../account_screen.dart';
import '../home_shell.dart';

/// Phase 1 stub. Friends, challenges, and leaderboards land with online PvP.
/// Hosts the account (sign-in / create-account) entry point, since accounts
/// are the prerequisite for the social features to come.
class SocialTab extends StatelessWidget {
  const SocialTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(title: 'Social'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            children: [
              if (auth != null) _AccountCard(auth: auth),
              if (auth != null) const SizedBox(height: 16),
              GamePanel(
                child: Column(
                  children: const [
                    Icon(Icons.groups, color: AppColors.textFaint, size: 40),
                    SizedBox(height: 10),
                    Text('Friends are coming soon',
                        style:
                            TextStyle(color: AppColors.text, fontSize: 15)),
                    SizedBox(height: 4),
                    Text(
                        'Add friends, challenge rivals, and climb the ranked '
                        'ladder once online play is live.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textDim, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Planned'),
              const _Soon(icon: Icons.person_add, title: 'Add friends'),
              const _Soon(icon: Icons.emoji_events, title: 'Ranked ladder (Elo)'),
              const _Soon(icon: Icons.sports_kabaddi, title: 'Challenge a friend'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AuthService auth;
  const _AccountCard({required this.auth});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!auth.signedIn) {
      return GamePanel(
        onTap: () => _open(context),
        borderColor: AppColors.gold,
        child: Row(
          children: [
            const Icon(Icons.account_circle, color: AppColors.gold, size: 34),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Playing as guest',
                      style:
                          TextStyle(color: AppColors.text, fontSize: 14)),
                  Text('Create an account to add friends and save progress',
                      style: TextStyle(
                          color: AppColors.textDim, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      );
    }
    return GamePanel(
      onTap: () => _open(context),
      child: Row(
        children: [
          const Icon(Icons.account_circle, color: AppColors.gold, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.displayName ?? 'Mage',
                    style:
                        const TextStyle(color: AppColors.text, fontSize: 14)),
                Text(
                    auth.emailVerified
                        ? '${auth.email} · verified'
                        : '${auth.email} · unverified',
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textFaint),
        ],
      ),
    );
  }
}

class _Soon extends StatelessWidget {
  final IconData icon;
  final String title;
  const _Soon({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: 0.55,
        child: GamePanel(
          child: Row(
            children: [
              Icon(icon, color: AppColors.gem, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 14)),
              ),
              const Icon(Icons.lock, color: AppColors.textFaint, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
