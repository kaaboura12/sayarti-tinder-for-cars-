import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../models/notification_model.dart' as notification_model;
import '../screens/conversations_screen.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final hasUnread = notificationProvider.unreadCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_rounded,
            size: 28,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor,
          ),
          onPressed: () => _showNotificationsModal(context),
        ),
        if (hasUnread)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsModal(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationsModal(context, notificationProvider, authProvider, isDarkMode),
    );
  }

  Widget _buildNotificationsModal(
    BuildContext context,
    NotificationProvider notificationProvider,
    AuthProvider authProvider,
    bool isDarkMode,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle and header
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: isDarkMode
                          ? AppTheme.darkHeadingMedium
                          : AppTheme.headingMedium,
                    ),
                    TextButton(
                      onPressed: () async {
                        final token = await authProvider.token;
                        if (token != null) {
                          await notificationProvider.markAllAsRead(token);
                        }
                      },
                      child: Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // Notifications list
              Expanded(
                child: _buildNotificationsList(
                  context,
                  notificationProvider,
                  authProvider,
                  isDarkMode,
                  scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    NotificationProvider notificationProvider,
    AuthProvider authProvider,
    bool isDarkMode,
    ScrollController scrollController,
  ) {
    final notifications = notificationProvider.notifications;
    
    if (notificationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(
          context,
          notification,
          notificationProvider,
          authProvider,
          isDarkMode,
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    notification_model.Notification notification,
    NotificationProvider notificationProvider,
    AuthProvider authProvider,
    bool isDarkMode,
  ) {
    final createdAt = DateTime.parse(notification.createdAt);
    final timeString = DateFormat.yMMMd().add_jm().format(createdAt);
    
    return InkWell(
      onTap: () async {
        // Handle notification click based on type
        if (notification.type == 'message' && notification.targetId != null) {
          // Mark as read
          final token = await authProvider.token;
          if (token != null) {
            await notificationProvider.markAsRead(notification.id, token);
          }
          
          // Close modal
          Navigator.pop(context);
          
          // Navigate to conversations screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConversationsScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead
            ? Colors.transparent
            : (isDarkMode ? Colors.blueGrey[900] : Colors.blue[50]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left indicator/icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // Read indicator
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'system':
        return Colors.purple;
      case 'alert':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message_rounded;
      case 'system':
        return Icons.info_rounded;
      case 'alert':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
} 