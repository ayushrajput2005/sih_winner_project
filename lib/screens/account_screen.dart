import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/screens/phone_login.dart';
import 'package:fasalmitra/screens/my_orders_screen.dart';
import 'package:fasalmitra/screens/orders_received_screen.dart';
import 'package:fasalmitra/screens/cart_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  static const String routeName = '/account';

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _checkLogin();
    if (AuthService.instance.isLoggedIn) {
      await AuthService.instance.fetchProfile();
      if (mounted) setState(() {});
    }
  }

  void _checkLogin() {
    final user = AuthService.instance.cachedUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.cachedUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: Text(LanguageService.instance.t('myAccount'))),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        user['name']?[0] ?? 'U',
                        style: TextStyle(
                          fontSize: 32,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user['name'] ?? 'Unknown User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(user['phone'] ?? ''),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user['state'] ?? 'India',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Menu Options
                    _buildMenuTile(
                      icon: Icons.shopping_cart,
                      title: LanguageService.instance.t('myCart'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(CartScreen.routeName),
                    ),
                    _buildMenuTile(
                      icon: Icons.list_alt,
                      title: LanguageService.instance.t('myOrders'),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(MyOrdersScreen.routeName),
                    ),
                    _buildMenuTile(
                      icon: Icons.storefront,
                      title: LanguageService.instance.t('ordersReceived'),
                      subtitle: LanguageService.instance.t('forYourListings'),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(OrdersReceivedScreen.routeName),
                    ),
                    const Divider(),
                    _buildMenuTile(
                      icon: Icons.logout,
                      title: LanguageService.instance.t('logout'),
                      color: Colors.red,
                      onTap: () async {
                        await AuthService.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
