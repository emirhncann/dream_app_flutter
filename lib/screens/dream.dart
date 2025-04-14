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
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  
  // Speech to text değişkenleri
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeechEnabled = false;
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: "AIzaSyBaLCeVvlutMg6kKYrv_ttEqhHcWVPboq4",
    );
    _testGeminiConnection();
    _initSpeech();
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

  // Speech to text başlatma
  Future<void> _initSpeech() async {
    _isSpeechEnabled = await _speech.initialize(
      onError: (error) => print('Speech Error: $error'),
      onStatus: (status) => print('Speech Status: $status'),
      debugLogging: true,
    );
    setState(() {});
  }

  // Ses kaydını başlat/durdur
  Future<void> _toggleListening(BuildContext context) async {
    if (!_isSpeechEnabled) {
      // İzin kontrolü
      _isSpeechEnabled = await _speech.initialize(
        onError: (error) => print('Speech Error: $error'),
        onStatus: (status) => print('Speech Status: $status'),
        debugLogging: true,
      );
      
      if (!_isSpeechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mikrofon izni gerekli. Lütfen ayarlardan izin verin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (!_isListening) {
      // Coin kontrolü
      if (userProvider.coins < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesli anlatım için 50 coin gerekiyor.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Coinleri düş
      await userProvider.deductCoins(50);
      
      // Ses kaydını başlat
      if (await _speech.listen(
        onResult: (result) {
          setState(() {
            dreamText = result.recognizedWords;
          });
        },
        localeId: 'tr_TR',
        cancelOnError: true,
      )) {
        setState(() => _isListening = true);
        _showAnimation = true;
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _showAnimation = false;
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
        // Şu anki zamanı al
        DateTime now = DateTime.now();
        // 5 dakika sonrasını hesapla
        DateTime timerEnd = now.add(Duration(minutes: 5));

        final userEmail = _auth.currentUser?.email;
        if (userEmail == null) throw Exception('Kullanıcı oturumu bulunamadı.');

        // Firestore'a kaydet
        await _firestore
            .collection('users')
            .doc(userEmail)
            .collection('yorumlar')
            .add({
          'ruya': dreamText,
          'yorum': response.text,
          'tarih': FieldValue.serverTimestamp(),
          'isTimerActive': true,
          'timerEnd': Timestamp.fromDate(timerEnd),
          'userBirthDate': userBirthDate,
          'userGender': userGender,
          'userName': userName,
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
                    'Rüyanı Anlat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rüyanı sesli veya yazılı olarak anlatabilirsin',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Mikrofon Butonu
                    if (!_isListening && dreamText.isEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF3D2C8D),
                              Color(0xFF1A1034),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleListening(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Rüyanı Sesli Anlat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Mikrofona dokun ve rüyanı anlatmaya başla',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Dinleme Animasyonu
                    if (_isListening)
                      Container(
                        margin: EdgeInsets.only(bottom: 24),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF3D2C8D),
                              Color(0xFF1A1034),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Lottie.asset(
                              'assets/gif/mic.json',
                              width: 150,
                              height: 150,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Seni Dinliyorum...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Metin Alanı
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3D2C8D),
                            Color(0xFF1A1034),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        maxLines: 8,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rüyanı buraya yazabilirsin...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                          contentPadding: EdgeInsets.all(20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),

                    // Gönder Butonu
                    if (dreamText.isNotEmpty || dreamText.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: ElevatedButton(
                          onPressed: _submitDream,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF2C1F63),
                            minimumSize: Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded),
                              SizedBox(width: 8),
                              Text(
                                'Rüyamı Yorumla',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  void _submitDream() async {
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
