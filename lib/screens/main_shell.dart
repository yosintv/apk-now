import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/banner_ad_widget.dart';
import '../providers/config_provider.dart';
import '../models/app_config.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Task 4: Fix Layout Overflow - prevent keyboard-related overflows
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/headerimage.png',
          height: 35,
          fit: BoxFit.contain,
        ),
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1), 
            width: 1
          ),
        ),
      ),
      drawer: _buildDrawer(context, config),
      body: navigationShell,
      // Task 4: Finalize UI Layout - One Sticky Ad & Prevents Overflow
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Essential to prevent 6px overflow
          children: [
            // Exactly one BannerAdWidget here as requested
            const BannerAdWidget(),
            
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onTabSelected,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(context).unselectedWidgetColor,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sports_soccer_outlined),
                    activeIcon: Icon(Icons.sports_soccer_rounded),
                    label: 'Football',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sports_cricket_outlined),
                    activeIcon: Icon(Icons.sports_cricket_rounded),
                    label: 'Cricket',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.newspaper_outlined),
                    activeIcon: Icon(Icons.newspaper_rounded),
                    label: 'News',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppConfig config) {
    return Drawer(
      backgroundColor: AppColors.drawerBackground,
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'YoSinTV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '24x7 - Football | Cricket',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildDrawerTile(
                  context,
                  icon: Icons.home_rounded,
                  title: 'Home',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(0);
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.sports_soccer_rounded,
                  title: 'Football',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(1);
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.sports_cricket_rounded,
                  title: 'Cricket',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(2);
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.newspaper_rounded,
                  title: 'News',
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(3);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildSocialButton(
                  text: 'Telegram Community',
                  color: AppColors.telegram,
                  icon: Icons.send_rounded,
                  onTap: () => _launchURL(config.telegramLink),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  text: 'WhatsApp Support',
                  color: AppColors.whatsapp,
                  icon: Icons.chat_rounded,
                  onTap: () => _launchURL(config.whatsappLink),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Version 1.1',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white60,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        tileColor: isSelected ? AppColors.accent.withOpacity(0.8) : Colors.transparent,
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
