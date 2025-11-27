import 'package:flutter/material.dart';
import 'package:tg_store/admin_panel/presentation/screens/login_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/products_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/categories_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/orders_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/settings_screen.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // По умолчанию показываем экран логина
    return const LoginScreen();
  }
}

/// Главный экран админ-панели (показывается после успешной авторизации)
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // TODO: Получать businessSlug из контекста или настроек
  static const String defaultBusinessSlug = 'default-business';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Выход - возвращаемся на экран логина
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            icon: Icons.inventory_2,
            title: 'Товары',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductsScreen(
                    businessSlug: defaultBusinessSlug,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.category,
            title: 'Категории',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoriesScreen(
                    businessSlug: defaultBusinessSlug,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.shopping_cart,
            title: 'Заказы',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersScreen(
                    businessSlug: defaultBusinessSlug,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.settings,
            title: 'Настройки',
            color: Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    businessSlug: defaultBusinessSlug,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

