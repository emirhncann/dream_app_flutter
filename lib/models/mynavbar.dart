import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:flutter/material.dart';
import 'package:dream_app_flutter/screens/dream_interpretations.dart';


class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1d0042), Color(0xFF644092)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
      
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedIndex == 0 ? Color(0xFF6602ad).withOpacity(0.2) : Colors.transparent,
                ),
                child: Icon(Icons.home_rounded),
              ),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedIndex == 1 ? Color(0xFF6602ad).withOpacity(0.2) : Colors.transparent,
                ),
                child: Icon(Icons.book_rounded),
              ),
              label: 'Yorumlarım',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedIndex == 2 ? Color(0xFF6602ad).withOpacity(0.2) : Colors.transparent,
                ),
                child: Icon(Icons.person_rounded),
              ),
              label: 'Profil',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Color(0xFF6602ad),
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
          ),
          elevation: 0,
          onTap: (index) {
            onItemTapped(index);
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DreamInterpretations()),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DreamInterpretations()),
                );
                break;
            }
          },
        ),
      ),
    );
  }
}