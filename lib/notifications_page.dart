import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Color Palette
  static const Color deepBlue = Color(0xFF0077B6);
  static const Color turquoise = Color(0xFF00B4D8);
  static const Color coralOrange = Color(0xFFFF6F61);
  static const Color seaGreen = Color(0xFF2EC4B6);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color darkNavy = Color(0xFF023047);

  final List<Map<String, dynamic>> alerts = [
    {
      'title': 'High Wave Warning',
      'description': 'Wave height 3-4m expected along Mumbai coast',
      'time': '2 hours ago',
      'severity': 'High',
      'icon': Icons.water,
      'isRead': false,
    },
    {
      'title': 'Weather Advisory',
      'description': 'Strong winds forecasted for fishing zones',
      'time': '4 hours ago',
      'severity': 'Medium',
      'icon': Icons.air,
      'isRead': true,
    },
    {
      'title': 'Vessel Safety Update',
      'description': 'All vessels to carry emergency equipment',
      'time': '6 hours ago',
      'severity': 'Low',
      'icon': Icons.directions_boat,
      'isRead': false,
    },
    {
      'title': 'Cyclone Alert',
      'description': 'Moderate intensity cyclone forming in Bay of Bengal',
      'time': '8 hours ago',
      'severity': 'High',
      'icon': Icons.storm,
      'isRead': true,
    },
    {
      'title': 'Safety Update',
      'description': 'All fishing vessels advised to return by 6 PM today',
      'time': '12 hours ago',
      'severity': 'Medium',
      'icon': Icons.warning,
      'isRead': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 4,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildNotificationCard(alert, index);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> alert, int index) {
    Color severityColor = _getSeverityColor(alert['severity']);

    return Dismissible(
      key: Key('notification_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          alerts.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification dismissed')),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert['isRead'] ? Colors.white : lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              width: 4,
              color: severityColor,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                alert['icon'],
                color: severityColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkNavy,
                          ),
                        ),
                      ),
                      if (!alert['isRead'])
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: coralOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    alert['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: darkNavy.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        alert['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: darkNavy.withOpacity(0.5),
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert['severity'].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'High':
        return coralOrange;
      case 'Medium':
        return turquoise;
      case 'Low':
        return seaGreen;
      default:
        return deepBlue;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var alert in alerts) {
        alert['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All notifications marked as read')),
    );
  }
}
