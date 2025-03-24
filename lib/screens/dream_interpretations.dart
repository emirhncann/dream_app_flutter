import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:dream_app_flutter/screens/dream.dart';

class DreamInterpretations extends StatefulWidget {
  @override
  _DreamInterpretationsState createState() => _DreamInterpretationsState();
}

class _DreamInterpretationsState extends State<DreamInterpretations> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 1; // Yorumlarım seçili

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    Widget page;
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        // Zaten Yorumlarım sayfasındayız, bir şey yapmaya gerek yok
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dream()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1d0042),
              Color(0xFF8b64bd),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  SizedBox(height: 29),
                  Text(
                    'Geçmiş rüya yorumlarını burada görebilirsin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Yorumlar Listesi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(_auth.currentUser?.email)
                    .collection('yorumlar')
                    .orderBy('tarih', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Bir hata oluştu',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.nights_stay_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Henüz rüya yorumun bulunmuyor',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      var tarih = (data['tarih'] as Timestamp).toDate();
                      var formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(tarih);

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF783FA6).withOpacity(0.15),
                              Color(0xFF644092).withOpacity(0.25),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1d0042).withOpacity(0.95),
                                          Color(0xFF644092).withOpacity(0.95),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 25,
                                          offset: Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Rüya Yorumu',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.close, color: Colors.white),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Rüyan:',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            data['ruya'] ?? '',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                          SizedBox(height: 24),
                                          Text(
                                            'Yorumu:',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            data['yorum'] ?? '',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.nights_stay_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    data['ruya'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
} 