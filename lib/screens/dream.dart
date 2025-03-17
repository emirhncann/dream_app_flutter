import 'dart:async';

import 'package:dream_app_flutter/const/api.dart';
import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:dream_app_flutter/providers/user_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lottie/lottie.dart';

class Dream extends StatefulWidget {
  const Dream({super.key});

  @override
  State<Dream> createState() => _DreamState();
}

class _DreamState extends State<Dream> {
  int _selectedIndex = 0;
  String dreamText = ""; // Kullanıcının rüya metnini tutar
  int maxLength = 1000; // Karakter sınırı
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gemini API için model
  late GenerativeModel _model;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: "AIzaSyBaLCeVvlutMg6kKYrv_ttEqhHcWVPboq4",
    );
    _testGeminiConnection();
  }

  // Gemini API bağlantı testi
  Future<void> _testGeminiConnection() async {
    try {
      final testPrompt = 'Merhaba';
      final content = [Content.text(testPrompt)];
      await _model.generateContent(content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rüya yorumlama servisi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Rüya yorumlama fonksiyonu
  Future<String> _interpretDream(String dreamText) async {
    try {
      // Kullanıcı bilgilerini al
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) {
        throw Exception('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
      }

      // Kullanıcının detay bilgilerini al
      final userDoc = await _firestore.collection('users').doc(userEmail).get();
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? 'Canım';
      final userGender = userData['gender'] ?? '';
      final userBirthDate = userData['dg'] ?? '';
      final hitap = userGender.toLowerCase() == 'kadın' ? 'canım' : 'yakışıklı';

      // Önce API'den yanıt alalım
      final prompt = '''
      Ben deneyimli bir rüya yorumcusuyum ve Carl Jung'un analitik psikoloji teorisine göre rüyaları yorumluyorum. 
      Şimdi senin için özel bir yorum yapacağım ${userName} ${hitap}.

      Rüyan:
      $dreamText

      Yorumumda şu başlıkları kullanacağım ve samimi bir dille, falcı üslubuyla konuşacağım:

      1. İlk İzlenimim:
      (Rüyanın genel enerjisi ve ilk hissettiklerim)

      2. Jung'a Göre Semboller ve Arketipler:
      (Rüyadaki kolektif bilinçdışı sembolleri ve arketipleri)

      3. Gizli Mesajlar:
      (Bilinçaltından gelen özel mesajlar)

      4. Önerilerim:
      (Hayatında yapman gereken değişiklikler)

      Not: Kullanıcı Bilgileri
      - İsim: $userName
      - Cinsiyet: $userGender
      - Doğum Tarihi: $userBirthDate

      Lütfen bu bilgileri göz önünde bulundurarak, samimi ve kişiselleştirilmiş bir yorum yap. 
      "Canım", "güzelim", "yakışıklım" gibi hitaplar kullan ve falcı üslubuyla konuş.
      ''';

      final content = [Content.text(prompt)];
      
      final response = await _model.generateContent(content)
          .timeout(
            Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('İstek zaman aşımına uğradı canım, bir daha dener misin?'),
          );
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Ay canım bir sorun oldu, boş yanıt aldım. Tekrar dener misin?');
      }

      try {
        // Firestore'a kaydet
        await _firestore.collection('users').doc(userEmail).set({
          'email': userEmail,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore
            .collection('users')
            .doc(userEmail)
            .collection('yorumlar')
            .add({
          'ruya': dreamText,
          'yorum': response.text,
          'tarih': FieldValue.serverTimestamp(),
          'yorumcu': 'Saniye Abla',
          'userName': userName,
          'userGender': userGender,
          'userBirthDate': userBirthDate
        });

        print('Yorum başarıyla kaydedildi');
      } catch (e) {
        print('Firestore kayıt hatası: $e');
        throw Exception('Ay canım bir sorun çıktı, yorumunu kaydedemedim. Tekrar dener misin?');
      }
      
      return response.text!;
    } on TimeoutException {
      throw Exception('Canım bağlantıda sorun var galiba, biraz bekleyip tekrar dener misin?');
    } catch (e) {
      print('Rüya yorumlama hatası: $e');
      if (e.toString().contains('API key')) {
        throw Exception('Sistemde bir sorun var güzelim, biraz sonra tekrar dener misin?');
      }
      throw Exception(e.toString().contains('Exception:') ? e.toString() : 'Ay canım bir sorun çıktı, tekrar deneyebilir misin?');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height; // Ekran yüksekliği
    double screenWidth = MediaQuery.of(context).size.width;   // Ekran genişliği

    return Scaffold(
      appBar: CustomAppBar(),
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1d0042), // Üst kısım rengi
                  Color(0xFF8b64bd), // Alt kısım rengi
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                
                // Rüya metnini girebileceği TextField
                Container(
                  height: screenHeight * 0.6, // Yükseklik ekranın %60'ı
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF783FA6), // Arka plan rengi
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    maxLines: null, // Satır sayısını sınırlamamak için
                    maxLength: maxLength,
                    onChanged: (text) {
                      setState(() {
                        dreamText = text;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Rüyanı buraya yaz...",
                      hintStyle: TextStyle(color: Colors.white), // Hint style
                      border: InputBorder.none,
                      counterText: "", // Sayaç kısmını TextField içinden kaldırdık
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

                SizedBox(height: 10), // Boşluk

                SizedBox(height: 20), // Boşluk

                // "Rüyanı Yorumlat" butonu
                ElevatedButton(
                  onPressed: () {
                    yorumla(context); // Butona tıklandığında yorumla fonksiyonunu çalıştırır
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Color(0xFF6602ad), // Buton rengi
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Rüyanı Yorumlat",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Sabit sayaç kısmı sağ altta
          Positioned(
            right: 22,
            bottom: screenHeight * 0.16, // Alt kısma sabitlenmiş durumda
            child: Text(
              "${dreamText.length}/$maxLength",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

void yorumla(BuildContext context) async {
  if (dreamText.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lütfen önce rüyanızı yazın.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Coin kontrolü
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  if (userProvider.coins < 50) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yetersiz coin! Rüya yorumlatmak için 50 coin gerekiyor.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1d0042), Color(0xFF644092)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20.0),
            image: DecorationImage(
              image: AssetImage('assets/images/dream_bg.png'),
              fit: BoxFit.cover,
              opacity: 0.2,
            ),
          ),
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/gif/bulut.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20),
              Text(
                'Rüyanız yorumlanıyor...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    String interpretation = await _interpretDream(dreamText);
    
    // Yorumlama başarılı olduktan sonra coini düş
    await userProvider.deductCoins(50);
    
    setState(() {
      _isLoading = false;
    });
    
    Navigator.pop(context); // Loading dialogu kapat

    showDialog(
      context: context,
      builder: (BuildContext interpretContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1d0042), Color(0xFF644092)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20.0),
            image: DecorationImage(
              image: AssetImage('assets/images/stars_bg.png'),
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '-50',
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
                SizedBox(height: 20),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      interpretation,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(interpretContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6602ad),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Kapat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context); // Loading dialogu kapat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }
}


}
