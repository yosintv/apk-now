import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/banner_ad_widget.dart';
import '../providers/config_provider.dart';
import '../models/app_config.dart';

// Fades in the new branch content when the active tab index changes,
// without unmounting the other branches (IndexedStack state is preserved).
class _BranchFader extends StatefulWidget {
  final int index;
  final Widget child;
  const _BranchFader({required this.index, required this.child});

  @override
  State<_BranchFader> createState() => _BranchFaderState();
}

class _BranchFaderState extends State<_BranchFader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_BranchFader old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: widget.child);
}

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
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context, config),
      body: _BranchFader(
        index: navigationShell.currentIndex,
        child: navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BannerAdWidget(),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      centerTitle: true,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, size: 24),
          color: AppColors.primary,
          splashRadius: 20,
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Image.asset(
        'assets/headerimage.png',
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text(
          'YoSinTV',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, size: 24),
          color: AppColors.textSecondary,
          splashRadius: 20,
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      shape: const Border(
        bottom: BorderSide(color: Color(0x0F000000), width: 1),
      ),
    );
  }

  // ── Material 3 NavigationBar ───────────────────────────────────────────────

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 200),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 22),
            selectedIcon:
                Icon(Icons.home_rounded, size: 22, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined, size: 22),
            selectedIcon: Icon(Icons.sports_soccer_rounded,
                size: 22, color: AppColors.primary),
            label: 'Football',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_cricket_outlined, size: 22),
            selectedIcon: Icon(Icons.sports_cricket_rounded,
                size: 22, color: AppColors.primary),
            label: 'Cricket',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined, size: 22),
            selectedIcon: Icon(Icons.newspaper_rounded,
                size: 22, color: AppColors.primary),
            label: 'News',
          ),
        ],
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context, AppConfig config) {
    return Drawer(
      backgroundColor: AppColors.drawerBackground,
      width: 284,
      child: Column(
        children: [
          // Header gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.drawerGradientStart,
                  AppColors.drawerGradientEnd,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'YoSinTV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '24/7 · Football & Cricket',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0x15FFFFFF)),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _drawerSection('NAVIGATION'),
                _drawerTile(
                  context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(0);
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.sports_soccer_rounded,
                  label: 'Football',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(1);
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.sports_cricket_rounded,
                  label: 'Cricket',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(2);
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.newspaper_rounded,
                  label: 'News',
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(3);
                  },
                ),
                const SizedBox(height: 8),
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0x10FFFFFF),
                    indent: 20,
                    endIndent: 20),
                const SizedBox(height: 8),
                _drawerSection('MORE'),
                _drawerTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: 'About Us',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    _launchURL(config.aboutUsLink);
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    _launchURL(config.privacyPolicyLink);
                  },
                ),
              ],
            ),
          ),

          // Social + version
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              children: [
                _socialButton(
                  label: 'Telegram Community',
                  color: AppColors.telegram,
                  icon: Icons.send_rounded,
                  onTap: () => _launchURL(config.telegramLink),
                ),
                const SizedBox(height: 8),
                _socialButton(
                  label: 'WhatsApp Support',
                  color: AppColors.whatsapp,
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => _launchURL(config.whatsappLink),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Version 1.2.0',
                  style: TextStyle(
                    color: Color(0x40FFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0x40FFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.90)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0x8AFFFFFF),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xB3FFFFFF),
                    fontWeight: isSelected
                        ? FontWeight.w800
                        : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
