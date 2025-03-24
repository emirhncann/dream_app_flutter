import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dream_app_flutter/screens/login.dart';
import 'package:provider/provider.dart';
import 'package:dream_app_flutter/providers/user_provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool hasLeading; // Leading alanının gösterilip gösterilmeyeceğini belirler
  CustomAppBar({this.hasLeading = false});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppBar(
          backgroundColor: Color(0xFF5D009F),
          centerTitle: true,
          title: Text(
            '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: widget.hasLeading
              ? IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {},
                )
              : null,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return StreamBuilder<int>(
                    stream: userProvider.getCoinStream(),
                    builder: (context, snapshot) {
                      return Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.yellow),
                          SizedBox(width: 4),
                          Text(
                            '${snapshot.data ?? 0}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
            ),
          ],
        ),
        Positioned(
          top: 20.0,
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6602AD)
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/img/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
