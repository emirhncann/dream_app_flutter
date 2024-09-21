import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:flutter/material.dart';

class Dream extends StatefulWidget {
  const Dream({super.key});

  @override
  State<Dream> createState() => _DreamState();
}

class _DreamState extends State<Dream> {
  int _selectedIndex = 0;
  String dreamText = ""; // Kullanıcının rüya metnini tutar
  int maxLength = 1000; // Karakter sınırı

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                    // Butona basıldığında yapılacak işlemler
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
            right: 16,
            bottom: screenHeight * 0.15, // Alt kısma sabitlenmiş durumda
            child: Text(
              "${dreamText.length}/$maxLength",
              style: TextStyle(color: Colors.white, fontSize: 14),
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
}
