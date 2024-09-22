import 'dart:async';
import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:flutter/material.dart';

class DreamComments extends StatefulWidget {
  @override
  _DreamCommentsState createState() => _DreamCommentsState();
}

class _DreamCommentsState extends State<DreamComments> {
  int _selectedIndex = 0;

  // Örnek rüya yorumları
  final List<String> comments = [
    "Rüyada uçmak, özgürlük ve hayallerin peşinden koşma arzusunu simgeler.",
    "Rüyada yılan görmek, korkuların ve içsel çatışmaların sembolüdür.",
    "Rüyada su görmek, duyguların ve ruhsal durumun ifadesidir."
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: ListView.builder(
        itemCount: comments.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(10),
            elevation: 5,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                comments[index],
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
