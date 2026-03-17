import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_provider.dart';
import '../../../../services/notification_service.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/app_appbar.dart';
class NotificationsPage extends StatefulWidget {
const NotificationsPage({super.key});
@override
State<NotificationsPage> createState() => _NotificationsPageState();
}
class _NotificationsPageState extends State<NotificationsPage>
with SingleTickerProviderStateMixin {
late TabController _tabController;
@override
void initState() {
super.initState();
_tabController = TabController(length: 2, vsync: this);
}
@override
void dispose() {
_tabController.dispose();
super.dispose();
}
@override
Widget build(BuildContext context) {
final provider = context.watch<AppProvider>();
final isDark = Theme.of(context).brightness == Brightness.dark;
return Scaffold(
  backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
  appBar: AppBar(
    title: const Text('Notifications',),
    titleTextStyle: AppTextStyles.h4.copyWith(color: Colors.white),
     iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    backgroundColor: isDark ? AppColors.darkBackground : AppColors.primary,
    bottom: TabBar(
      controller: _tabController,
      labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      labelColor: AppColors.white,
      unselectedLabelColor: AppColors.textHint,
      indicatorColor: AppColors.primary,
      tabs: const [
        Tab(text: 'Non lues'),
        Tab(text: 'Toutes'),
      ],
    ),
  ),
  body: TabBarView(
    controller: _tabController,
    children: [
      _buildNotificationList(provider, unreadOnly: true),
      _buildNotificationList(provider, unreadOnly: false),
    ],
  ),
);
}
Widget _buildNotificationList(AppProvider provider, {required bool unreadOnly}) {
final notifications = unreadOnly
? provider.notifications.where((n) => !n.isRead).toList()
: provider.notifications;
if (notifications.isEmpty) {
  return EmptyState(
    icon: Icons.notifications_none,
    title: unreadOnly ? 'Aucune notification non lue' : 'Aucune notification',
    subtitle: unreadOnly
        ? 'Vous êtes à jour !'
        : 'Les notifications apparaîtront ici',
  );
}

return ListView.separated(
  padding: const EdgeInsets.all(20),
  itemCount: notifications.length,
  separatorBuilder: (_, __) => const SizedBox(height: 12),
  itemBuilder: (context, index) {
    final notification = notifications[index];
    return _buildNotificationCard(context, notification, provider);
  },
);
}
Widget _buildNotificationCard(
BuildContext context,
NotificationModel notification,
AppProvider provider,
) {
final isDark = Theme.of(context).brightness == Brightness.dark;
final timeAgo = _getTimeAgo(notification.createdAt);
return Dismissible(
  key: Key(notification.id),
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.delete, color: Colors.white),
  ),
  direction: DismissDirection.endToStart,
  onDismissed: (_) => provider.deleteNotification(notification.id),
  child: GestureDetector(
    onTap: () {
      if (!notification.isRead) {
        provider.markNotificationAsRead(notification.id);
      }
      _handleNotificationTap(context, notification);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? (isDark ? AppColors.darkSurface : AppColors.white)
            : notification.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? (isDark ? AppColors.darkBorder : AppColors.border)
              : notification.color.withOpacity(0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: notification.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.h4.copyWith(
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: notification.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppDivider(),
          const SizedBox(height: 12),
          Text(
            notification.body,
            style: AppTextStyles.body.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  ),
);
}
void _handleNotificationTap(BuildContext context, NotificationModel notification) {
// Navigation selon le type de notification
switch (notification.type) {
case NotificationType.medicationReminder:
case NotificationType.medicationRenewal:
Navigator.pushNamed(context, '/reminders');
break;
case NotificationType.missedMeasurement:
case NotificationType.doctorAppointment:
if (context.read<AppProvider>().isPatient) {
Navigator.pushNamed(context, '/followup');
}
break;
case NotificationType.screeningReminder:
Navigator.pushNamed(context, '/reminders');
break;
case NotificationType.eventReminder:
Navigator.pushNamed(context, '/events');
break;
default:
break;
}
}
String _getTimeAgo(DateTime dateTime) {
final now = DateTime.now();
final difference = now.difference(dateTime);
if (difference.inSeconds < 60) {
  return 'À l\'instant';
} else if (difference.inMinutes < 60) {
  return 'Il y a ${difference.inMinutes} min';
} else if (difference.inHours < 24) {
  return 'Il y a ${difference.inHours}h';
} else if (difference.inDays < 7) {
  return 'Il y a ${difference.inDays}j';
} else {
  return DateFormat('dd/MM/yyyy').format(dateTime);
}
}
}