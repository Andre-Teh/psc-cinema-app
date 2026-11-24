import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String message;
  final String date;
  final IconData icon;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.date,
    required this.icon,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> notifications = [
    NotificationItem(
      icon: Icons.card_giftcard,
      title: "Your profile has been completed",
      message: "You have unlocked your rewards. Earn and redeem now!",
      date: "TODAY",
    ),
    NotificationItem(
      icon: Icons.error,
      title: "Order failed - FINAL DESTINATION: BLOODLINES",
      message:
          "An error occurred while processing your purchase. Please try again.",
      date: "13 MAY 2025",
    ),
    NotificationItem(
      icon: Icons.error,
      title: "Order failed - FINAL DESTINATION: BLOODLINES",
      message:
          "An error occurred while processing your purchase. Please try again.",
      date: "13 MAY 2025",
    ),
    NotificationItem(
      icon: Icons.error,
      title: "Order failed - THUNDERBOLTS*",
      message:
          "An error occurred while processing your purchase. Please try again.",
      date: "13 MAY 2025",
    ),
    NotificationItem(
      icon: Icons.error,
      title: "Order failed - FINAL DESTINATION: BLOODLINES",
      message:
          "An error occurred while processing your purchase. Please try again.",
      date: "13 MAY 2025",
    ),
    NotificationItem(
      icon: Icons.error,
      title: "Order failed - THUNDERBOLTS*",
      message:
          "An error occurred while processing your purchase. Please try again.",
      date: "12 MAY 2025",
    ),
    NotificationItem(
      icon: Icons.local_movies,
      title: "Happy Mothers Day ❤️💕🥰💕",
      message:
          "Movies from RM10 only—give her the movie surprise she deserves ❤️👑",
      date: "11 MAY 2025",
    ),
  ];

  void markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(229, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              "NOTIFICATIONS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    notifications.where((n) => !n.isRead).isEmpty
                        ? Colors.grey
                        : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${notifications.where((n) => !n.isRead).length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      item.isRead = true;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          item.isRead
                              ? Colors.grey.shade800
                              : Colors.red.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              item.isRead
                                  ? Colors.grey.shade700
                                  : Colors.redAccent,
                          radius: 22,
                          child: Icon(item.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: markAllAsRead,
              child: const Text(
                "MARK ALL AS READ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
