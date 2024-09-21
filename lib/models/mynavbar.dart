import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  CustomBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF5D009F), // Background color #783fa6
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 15,
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent, // Keep background transparent to show Container color
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 30), // Modern home icon
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded, size: 30), // Modern comments icon
            label: 'Yorumlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded, size: 30), // Modern account icon
            label: 'Hesabım',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.white, // Selected icon color
        unselectedItemColor: Colors.white.withOpacity(0.7), // Unselected icon color with opacity
        selectedFontSize: 14, // Font size for selected item
        unselectedFontSize: 12, // Font size for unselected item
        type: BottomNavigationBarType.fixed, // Ensures icons stay aligned
        onTap: onItemTapped,
        elevation: 0, // Removes default shadow for cleaner look
      ),
    );
  }
}