import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:dream_app_flutter/screens/dream.dart';
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
    setState(() {
      _selectedIndex = index;
    });
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
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              // Rüya Yorumlama Kartı
              GestureDetector(
                onTap: () => _checkAndNavigate(context, 50, Dream()),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2B1B5C),  // Koyu gece mavisi
                        Color(0xFF4B3C8C),  // Orta ton mor
                        Color(0xFF8B72BE),  // Açık mor
                      ],
                      stops: [0.2, 0.6, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Arka plan deseni
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // İçerik
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.nights_stay,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 32,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Rüyanı Yorumlat',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: userProvider.coins >= 50 
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
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
                                        '50',
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
                            SizedBox(height: 16),
                            Text(
                              'Rüyalarının gizli anlamlarını keşfet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                            Spacer(),
                            Text(
                              'Mevcut Coin: ${userProvider.coins}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
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
              SizedBox(height: 20),
              // Günlük Astroloji Kartı
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A237E),  // Koyu gece mavisi
                      Color(0xFF3949AB),  // Orta ton mavi
                      Color(0xFF5C6BC0),  // Açık mavi
                    ],
                    stops: [0.2, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Arka plan deseni
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // İçerik
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white.withOpacity(0.9),
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Günlük Astroloji',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Yıldızlar bugün senin için ne diyor?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
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
                                      '30',
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

