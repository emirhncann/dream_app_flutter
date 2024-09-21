import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:dream_app_flutter/screens/dream.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1d0042), // Üst kısım rengi
              Color(0xFF8b64bd), // Alt kısım rengi
            ],
            begin: Alignment.topCenter, // Gradient'in başlangıç noktası
            end: Alignment.bottomCenter, // Gradient'in bitiş noktası
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40), // Üstten boşluk
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Saniye Ablaya Hoşgeldin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 5), // Hoşgeldin ve username arasında boşluk
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Ahmet Numan', // Burayı dinamik olarak güncelleyebilirsiniz
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20), // Kullanıcı adından kartlara kadar boşluk
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SizedBox(height: 20), // Kartlardan önce boşluk
                  
                  GestureDetector(
                    onTap: () {
                      dream(); // Tıklanınca rüya yorumlama fonksiyonu çalışacak
                    },
                    child: Stack(
                      children: [
                        // Resim
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://img001.prntscr.com/file/img001/f3toGkpMThWVKrIQlesj-Q.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Gradient
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.9), // Soldaki mor renk
                                Colors.purple.withOpacity(0.1), // Sağda şeffaflık
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Kart içeriği
                        const Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Rüyamı Yorumla',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      astrology(); // Tıklanınca astroloji fonksiyonu çalışacak
                    },
                    child: Stack(
                      children: [
                        // Resim
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://img001.prntscr.com/file/img001/ybLlSVNmSGCUldaXLRCjAA.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Gradient
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.9), // Soldaki mor renk
                                Colors.purple.withOpacity(0.1), // Sağda şeffaflık
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Kart içeriği
                        const Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Günlük Astroloji Yorumu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
