import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dream_app_flutter/screens/login.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool hasLeading; // Leading alanının gösterilip gösterilmeyeceğini belirler
  CustomAppBar({this.hasLeading = false});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _credits = 0;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    try {
      final user = _auth.currentUser;
      if (user?.email != null) {
        final userData = await _firestore
            .collection('users')
            .doc(user!.email)
            .get();

        if (userData.exists) {
          setState(() {
            _credits = userData.data()?['coin'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Kredi yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allows overflow to make sure the logo appears fully
      children: [
        AppBar(
          backgroundColor: Color(0xFF5D009F), // Arka plan rengi (#5d009f)
          centerTitle: true,
          leading: widget.hasLeading
              ? IconButton(
                  icon: Icon(Icons.menu), // Sol tarafta menü ikonu
                  onPressed: () {
                    // Menüye basılınca yapılacaklar
                  },
                )
              : null, // Eğer hasLeading false ise leading boş olacak
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.yellow),
                  SizedBox(width: 4),
                  Text(
                    '$_credits', // Firestore'dan çekilen kredi
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
            ),
          ],
        ),
        Positioned(
          top: 20.0, // Adjusted to move above the app bar
          left: MediaQuery.of(context).size.width / 2 - 50, // Updated for centering based on new size
          child: Container(
            width: 100, // Increased width
            height: 100, // Increased height
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6602AD) // Yuvarlak şeklin rengi
            ),
           /* child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/logo.png'), // Logo burada
            ),*/
          ),
        ),
      ],
    );
  }
}
