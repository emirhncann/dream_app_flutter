import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool hasLeading; // Leading alanının gösterilip gösterilmeyeceğini belirler
  CustomAppBar({this.hasLeading = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allows overflow to make sure the logo appears fully
      children: [
        AppBar(
          backgroundColor: Color(0xFF5D009F), // Arka plan rengi (#5d009f)
          centerTitle: true,
          leading: hasLeading
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
                    '150', // Coin değeri
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
