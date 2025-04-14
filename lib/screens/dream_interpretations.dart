import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:dream_app_flutter/screens/dream.dart';
import 'package:lottie/lottie.dart';

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

  // Rüya metnini kısaltma fonksiyonu
  String _getSummaryText(String text) {
    // Metni nokta, virgül veya boşluklardan böl
    List<String> words = text.split(RegExp(r'[.,\s]+'));
    
    // İlk 5 kelimeyi al (veya metin daha kısaysa tümünü)
    words = words.take(5).toList();
    
    // Kelimeleri birleştir ve sonuna ... ekle
    return words.join(' ') + (text.split(' ').length > 5 ? '...' : '');
  }

  void _showWaitDialog(Map<String, dynamic> data, QueryDocumentSnapshot doc) {
    final now = DateTime.now();
    final timerEnd = data['timerEnd'] as Timestamp;
    final end = timerEnd.toDate();
    if (now.isBefore(end)) {
      final remaining = end.difference(now);
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1d0042),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFF6602ad), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/gif/bulut.json',
                  width: 150,
                  height: 150,
                ),
                SizedBox(height: 20),
                Text(
                  'Rüyanız Yorumlanıyor. Biraz Bekleteceğim',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
               
                SizedBox(height: 10),
                Text(
                  'bekleyin veya',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAd(doc.id);
                  },
                  icon: Icon(Icons.play_circle_outline),
                  label: Text('Reklam İzleyerek Hemen Açın'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 45),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Beklemeye Devam Et',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showAd(String documentId) async {
    // TODO: Burada reklam gösterilecek
    // Reklam başarıyla tamamlandığında:
    await _firestore
        .collection('users')
        .doc(_auth.currentUser?.email)
        .collection('yorumlar')
        .doc(documentId)
        .update({
      'isTimerActive': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C1F63),
              Color(0xFF1A1034),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Başlık
            Container(
              padding: EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rüya Yorumlarım',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Geçmiş rüya yorumlarını burada görebilirsin',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
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
                          Lottie.asset(
                            'assets/gif/empty.json',
                            width: 200,
                            height: 200,
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Henüz rüya yorumun bulunmuyor',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isTimerActive = data['isTimerActive'] ?? false;
                      final timerEnd = data['timerEnd'] as Timestamp;
                      final now = DateTime.now();
                      final canView = !isTimerActive || now.isAfter(timerEnd.toDate());
                      final date = (data['tarih'] as Timestamp).toDate();
                      final formattedDate = DateFormat('d MMMM y', 'tr_TR').format(date);

                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF3D2C8D).withOpacity(0.9),
                                Color(0xFF1A1034).withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (!canView) {
                                  _showWaitDialog(data, doc);
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF3D2C8D).withOpacity(0.95),
                                              Color(0xFF1A1034).withOpacity(0.95),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.white.withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.auto_awesome,
                                                        color: Colors.amber,
                                                        size: 24,
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        'Rüya Yorumu',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.close, color: Colors.white70),
                                                    onPressed: () => Navigator.pop(context),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              child: SingleChildScrollView(
                                                padding: EdgeInsets.all(24),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Rüyan',
                                                      style: TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      data['ruya'] ?? '',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        height: 1.6,
                                                      ),
                                                    ),
                                                    SizedBox(height: 24),
                                                    Text(
                                                      'Yorumu',
                                                      style: TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      data['yorum'] ?? '',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        height: 1.6,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          !canView ? Icons.lock_clock : Icons.auto_awesome,
                                          color: !canView ? Colors.amber : Colors.white70,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            formattedDate,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      _getSummaryText(data['ruya'] ?? ''),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (!canView) ...[
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timer,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Yorumu görmek için tıkla',
                                              style: TextStyle(
                                                color: Colors.amber,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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