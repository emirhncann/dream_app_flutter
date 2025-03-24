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
import 'package:dream_app_flutter/screens/dream_interpretations.dart';
import 'package:dream_app_flutter/screens/homepage.dart';

class Dream extends StatefulWidget {
  const Dream({super.key});

  @override
  State<Dream> createState() => _DreamState();
}

class _DreamState extends State<Dream> {
  int _selectedIndex = 2; // Profil seçili
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
          MaterialPageRoute(builder: (context) => DreamInterpretations()),
        );
        break;
      case 2:
        // Zaten Profil sayfasındayız
        break;
    }
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
      final userName = userData['first_name'] ?? 'Canım';
      final userGender = userData['gender'] ?? '';
      final userBirthDate = userData['dg'] ?? '';
      final hitap = userGender.toLowerCase() == 'kadın' ? 'canım' : 'yakışıklı';

      // Önce API'den yanıt alalım
      final prompt = '''
      Ben deneyimli bir rüya yorumcusuyum ve Carl Jung'un analitik psikoloji yaklaşımına göre rüyaları semboller ve arketipler üzerinden yorumluyorum.

Şimdi kullanıcıdan aldığım bilgilerle ona özel bir rüya yorumu yapacağım.

Kullanıcı Bilgileri:
– İsim: ${userName}
– Cinsiyet: ${userGender}
– Doğum Tarihi: ${userBirthDate}

Rüya Metni:
${dreamText}

Şu kurallara göre yaz:

Yorum tekdüze ve şablon gibi olmasın. Her rüya farklı bir tonda yorumlansın.

Rüyanın duygusuna göre yorumun atmosferi şekillensin: gizemli, huzurlu, içsel, coşkulu, hüzünlü vs.

Falcı-ruhlu ama yapay olmayan, doğal bir hitabetle yaz. "Canım", "tatlım", "yakışıklım", "güzel ruhlu" gibi ifadeleri bağlama uygun olarak kullan.

Jung'un teorisini temel al, ama bunu akademik dille değil, hikâye anlatır gibi, sezgisel ve etkileyici bir dille aktar.

Başlıklar zorunlu değil. Eğer rüyanın doğasına uygunsa bölümlere ayrılabilir ama bazen tümüyle akışkan ve serbest bir anlatım tercih edilebilir.

Yorumu, kullanıcının hayatında bir farkındalık yaratacak şekilde bitir. Ona içsel bir mesaj ver ya da bir öneride bulun.

Gerektiğinde kullanıcı ismini (örneğin: "Ahh ${userName}'cim...") içten bir dille aralara serpiştir.

Jung'a göre yorumladığından bahsetme.

doğum tarihinden her rüyada bahsetmek zorunda değilsin ayrıca gün ay yıl şeklinde doğum günü verme çok yapay duruyor
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
          'userBirthDate': userBirthDate,
          'timerEnd': Timestamp.fromDate(DateTime.now().add(Duration(minutes: 3))), // 3 dakika sonrası için timestamp
          'isTimerActive': true // Timer'ın aktif olup olmadığını belirten flag
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
                  Color(0xFF1d0042),
                  Color(0xFF8b64bd),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  
                  // Başlık ve açıklama
                  Text(
                    "Rüyanı Anlat",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Rüyanı detaylı bir şekilde anlatırsan daha iyi bir yorum alabirsin",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  
                  // Rüya yazma alanı
                  Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Color(0xFF783FA6).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          maxLines: null,
                          maxLength: maxLength,
                          onChanged: (text) {
                            setState(() {
                              dreamText = text;
                            });
                          },
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: "Rüyanı buraya yaz...",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            counterText: "",
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "${dreamText.length}/$maxLength",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                  // Yorumlat butonu
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        yorumla(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFF6602ad),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Rüyanı Yorumlat",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
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
    
    // Başarılı mesajı göster ve yorumlar sayfasına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rüyanız başarıyla yorumlandı!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Yorumlar sayfasına yönlendir
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DreamInterpretations()),
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
