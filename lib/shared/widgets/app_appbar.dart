import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_provider.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final TabBar? tabBar;
  final PreferredSizeWidget? bottom;
  final ispatient;

  const AppAppBar({
    super.key,
    required this.title,
    this.tabBar,
    this.bottom,
    this.ispatient = false,
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

      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: title,
      ),
            
      actions: [
        if(ispatient)
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
    final unreadCount = provider.unreadNotificationsCount;

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
              onPressed: () {Navigator.pushNamed(context, '/notifications');},
              icon: const Icon(Icons.notifications_outlined, size: 22),
            ),
             if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
         ],
       ),
    );
  }
}