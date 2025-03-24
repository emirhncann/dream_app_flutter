import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:dream_app_flutter/screens/dream.dart';
import 'package:dream_app_flutter/screens/dream_interpretations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:dream_app_flutter/providers/user_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _firstName = '';
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // UserProvider'dan coin bilgisini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user?.email != null) {
        final userEmail = user!.email;
        print('UserEmail: $userEmail'); // Debug için

        final userData = await _firestore
            .collection('users')
            .doc(userEmail)  // uid yerine email kullanıyoruz
            .get();

        print('UserData exists: ${userData.exists}'); // Debug için
        print('UserData: ${userData.data()}'); // Debug için

        if (userData.exists) {
          setState(() {
            _firstName = userData.data()?['first_name'] ?? '';
          });
          print('FirstName: $_firstName'); // Debug için
        }
      }
    } catch (e) {
      print('Kullanıcı bilgisi yükleme hatası: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Zaten Ana Sayfa'dayız
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DreamInterpretations()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dream()),
        );
        break;
    }
  }

  void _checkAndNavigate(BuildContext context, int requiredCoins, Widget page) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.coins >= requiredCoins) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetersiz coin! ${requiredCoins} coin gerekiyor.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void dream() {
    // Rüya yorumlama sayfasına yönlendirme veya işlemler burada yapılacak
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Dream()), // Dream sayfasına yönlendirme
    );
    print("Rüya yorumla sayfası açıldı.");
  }

  void astrology() {
    // Astroloji yorumlama sayfasına yönlendirme veya işlemler burada yapılacak
    print("Astroloji yorumları sayfası açıldı.");
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
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
            SizedBox(height: 40), // Logo için boşluk
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Saniye Abla\'ya Hoşgeldin ${_firstName.isNotEmpty ? _firstName : 'Canım'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  SizedBox(height: 20),
                  // Rüya Yorumlama Kartı
                  GestureDetector(
                    onTap: () => _checkAndNavigate(context, 50, Dream()),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1d0042),
                            Color(0xFF644092),
                            Color(0xFF8b64bd),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Arka plan deseni
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // İçerik
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.nights_stay, color: Colors.white, size: 28),
                                    SizedBox(width: 12),
                                    Text(
                                      'Rüya Yorumla',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Rüyanı yaz, yapay zeka destekli detaylı yorumunu al',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Günlük Astroloji Kartı
                  GestureDetector(
                    onTap: () => _checkAndNavigate(context, 30, '/daily_astrology' as Widget),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2B1B5C),  // Koyu gece mavisi
                            Color(0xFF4B3C8C),  // Orta ton mor
                            Color(0xFF8B72BE),  // Açık mor
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Arka plan deseni
                          Positioned(
                            left: -20,
                            bottom: -20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // İçerik
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.stars, color: Colors.white, size: 28),
                                    SizedBox(width: 12),
                                    Text(
                                      'Günlük Astroloji',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Günlük burç yorumunu ve astrolojik tahminlerini öğren',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

