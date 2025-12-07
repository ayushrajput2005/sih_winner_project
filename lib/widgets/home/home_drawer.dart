import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/widgets/language_selector.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    this.onLogin,
    this.onRegister,
    this.onAboutUs,
    this.onCustomerCare,
  });

  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onAboutUs;
  final VoidCallback? onCustomerCare;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/gov_of_india.png',
                    height: 50,
                    fit: BoxFit.contain,
                    // Invert colors for white logo on dark bg if needed,
                    // but the image seems to be the original one.
                    // In HomeNavbar it was color filtered to white.
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'FasalMitra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(lang.t('login')),
            onTap: onLogin,
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: Text(lang.t('register')),
            onTap: onRegister,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(lang.t('aboutUs')),
            onTap: onAboutUs,
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text(lang.t('customerCare')),
            onTap: onCustomerCare,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Cart'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/cart');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/account');
            },
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: LanguageSelector(
              textColor: Colors.black,
              iconColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
