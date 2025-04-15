import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:dream_app_flutter/providers/user_provider.dart';
import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:dream_app_flutter/screens/profile.dart';
import 'package:dream_app_flutter/screens/comments.dart';
import 'package:lottie/lottie.dart';

class Astrology extends StatefulWidget {
  const Astrology({super.key});

  @override
  State<Astrology> createState() => _AstrologyState();
}

class _AstrologyState extends State<Astrology> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  bool _isLoading = false;
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: "AIzaSyBaLCeVvlutMg6kKYrv_ttEqhHcWVPboq4",
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
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
          MaterialPageRoute(builder: (context) => Profile()),
        );
        break;
    }
  }

  Future<void> _getAstrologyReading() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user?.email == null) {
        throw Exception('Lütfen önce giriş yapın.');
      }

      // Son yorum kontrolü
      final lastReading = await _firestore
          .collection('users')
          .doc(user!.email)
          .collection('astrology')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (lastReading.docs.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24),
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
                      width: 100,
                      height: 100,
                      child: Lottie.asset(
                        'assets/gif/astro.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Haftalık yorumunuzu görmek için reklam izleyin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Reklam izleme fonksiyonu eklenecek
                        _getAstrologyReading();
                      },
                      icon: Icon(Icons.play_circle_outline),
                      label: Text('Reklam İzle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.email).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bilgileri bulunamadı.');
      }

      final userData = userDoc.data() ?? {};
      final userName = userData['first_name'] ?? 'Canım';
      final userGender = userData['gender'] ?? '';
      final userBirthDate = userData['dg'] ?? '';
      final userBirthTime = userData['birth_time'] ?? '';
      final userBirthPlace = userData['birth_place'] ?? '';

      final prompt = '''
      Ben deneyimli bir astrologum ve bu hafta için kişiye özel bir astroloji yorumu yapacağım.

Kullanıcı Bilgileri:
– İsim: ${userName}
– Cinsiyet: ${userGender}
– Doğum Tarihi: ${userBirthDate}
${userBirthTime.isNotEmpty ? '– Doğum Saati: ${userBirthTime}' : ''}
${userBirthPlace.isNotEmpty ? '– Doğum Yeri: ${userBirthPlace}' : ''}

Şu kurallara göre yaz:

1. Yorumu 3 ana bölüme ayır:
   - **Genel Enerji ve Atmosfer**
   - **İlişkiler ve Duygusal Hayat**
   - **Kariyer ve Finans**

2. Her bölümde:
   - Mevcut gezegen konumlarının etkilerini açıkla
   - Önemli astrolojik olayları belirt
   - Pratik öneriler sun

3. Tarz:
   - Pozitif ve yapıcı bir dil kullan
   - Falcı-ruhlu ama yapay olmayan bir hitabet
   - "Canım", "tatlım" gibi samimi ifadeler kullan
   - Kullanıcının ismini bağlama uygun olarak kullan

4. Uzunluk:
   - Her bölüm yaklaşık 150-200 kelime
   - Toplam 500-600 kelime

5. Sonuç:
   - Haftanın genel özeti
   - Önemli tarihler ve saatler
   - Genel tavsiyeler
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Astroloji yorumu alınamadı. Lütfen tekrar deneyin.');
      }

      // Firestore'a kaydet
      await _firestore
          .collection('users')
          .doc(user.email)
          .collection('astrology')
          .add({
        'reading': response.text,
        'date': FieldValue.serverTimestamp(),
        'userBirthDate': userBirthDate,
        'userGender': userGender,
        'userName': userName,
        'userBirthTime': userBirthTime,
        'userBirthPlace': userBirthPlace,
        'type': 'astrology',
        'isReady': true, // Yorumu direkt hazır olarak işaretle
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DreamComments()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    'Haftalık Astroloji',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bu hafta için kişiye özel astroloji yorumun',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Ana İçerik
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/gif/astro.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _getAstrologyReading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5D4B9E),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Haftalık Yorumumu Göster',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
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