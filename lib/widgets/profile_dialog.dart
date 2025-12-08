import 'package:flutter/material.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/services/language_service.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.cachedUser;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        if (user == null) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    LanguageService.instance.t('authRequired'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(LanguageService.instance.t('loginToViewProfile')),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/login');
                    },
                    child: Text(LanguageService.instance.t('login')),
                  ),
                ],
              ),
            ),
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: theme.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      LanguageService.instance.t('userProfile'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildProfileRow(
                  context,
                  LanguageService.instance.t('usernameLabel'),
                  user['username']?.toString() ?? 'N/A',
                ),
                _buildProfileRow(
                  context,
                  LanguageService.instance.t('emailLabel'),
                  user['email']?.toString() ?? 'N/A',
                ),
                _buildProfileRow(
                  context,
                  LanguageService.instance.t('mobileLabel'),
                  user['mobile_no']?.toString() ??
                      user['phone']?.toString() ??
                      'N/A',
                ),
                _buildProfileRow(
                  context,
                  LanguageService.instance.t('stateLabel'),
                  user['state']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        LanguageService.instance.t('tokenBalance'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['token_balance']?.toString() ?? '0.00',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService.instance.signOut();
                      // Close dialog
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        // Force refresh/redirect to home
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      LanguageService.instance.t('logout'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
