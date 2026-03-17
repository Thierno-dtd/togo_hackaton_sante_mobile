import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_provider.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final TabBar? tabBar;
  final PreferredSizeWidget? bottom;

  const AppAppBar({
    super.key,
    required this.title,
    this.tabBar,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
      titleTextStyle: AppTextStyles.h4.copyWith(color: Colors.white),

      iconTheme: const IconThemeData(
        color: Colors.white,
      ),

      title: title,
      
      actions: [
        _NotifAction(provider: provider),

        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: const Icon(Icons.settings_outlined, size: 22),
        ),

        const SizedBox(width: 4),
      ],
      bottom: tabBar ?? bottom, // ← optionnel
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (tabBar?.preferredSize.height ?? bottom?.preferredSize.height ?? 0));
}

class _NotifAction extends StatelessWidget {
  final AppProvider provider;

  const _NotifAction({required this.provider});

  @override
  Widget build(BuildContext context) {
    return  Container(
      constraints: const BoxConstraints(),
      decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
      child: Stack(
          children: [
            IconButton(
              constraints: const BoxConstraints(),
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, size: 22),
            ),
            if (provider.overdueScreening.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
      ),
    );
  }
}