import 'package:flutter/material.dart';
import 'notifications_page.dart';
import 'citizenreport.dart';

class OceanPulseHomePage extends StatefulWidget {
  @override
  _OceanPulseHomePageState createState() => _OceanPulseHomePageState();
}

class _OceanPulseHomePageState extends State<OceanPulseHomePage> {
  final PageController _newsController = PageController();
  
  // Color Palette
  static const Color deepBlue = Color(0xFF0077B6);
  static const Color turquoise = Color(0xFF00B4D8);
  static const Color coralOrange = Color(0xFFFF6F61);
  static const Color seaGreen = Color(0xFF2EC4B6);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color darkNavy = Color(0xFF023047);

  final List<String> newsItems = [
    "🌊 INCOIS Advisory: High waves expected along west coast - Exercise caution",
    "⚠️ Cyclone alert: Moderate intensity cyclone forming in Bay of Bengal",
    "🛡️ Safety Update: All fishing vessels advised to return by 6 PM today",
    "📡 Weather Update: Strong winds (40-50 kmph) predicted for next 24 hours"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildTopBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: darkNavy,
      elevation: 4,
      toolbarHeight: 70,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: turquoise,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.waves,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OceanPulse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Marine Safety Monitor',
                style: TextStyle(
                  color: turquoise,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: coralOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            );
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNewsTicker(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNewsTicker() {
    return Container(
      height: 60,
      color: lightGray,
      child: Row(
        children: [
          Container(
            width: 120,
            height: double.infinity,
            color: deepBlue,
            child: Center(
              child: Text(
                'INCOIS\nADVISORY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _newsController,
              itemCount: newsItems.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      newsItems[index],
                      style: TextStyle(
                        fontSize: 14,
                        color: darkNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    return SizedBox.shrink();
  }

  Widget _buildBottomBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home, 'Home', true),
          _buildBottomNavItem(Icons.map, 'Map', false),
          _buildBottomNavItem(Icons.add_circle, 'Report', false, isCenter: true),
          _buildBottomNavItem(Icons.notifications, 'Alerts', false),
          _buildBottomNavItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive, {bool isCenter = false}) {
    return GestureDetector(
      onTap: () {
        if (label == 'Report') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HazardReportingPage()),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isCenter ? 8 : 6),
              decoration: BoxDecoration(
                color: isCenter
                    ? coralOrange
                    : isActive
                        ? deepBlue.withOpacity(0.1)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isCenter
                    ? Colors.white
                    : isActive
                        ? deepBlue
                        : Colors.grey,
                size: isCenter ? 24 : 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? deepBlue : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newsController.dispose();
    super.dispose();
  }
}