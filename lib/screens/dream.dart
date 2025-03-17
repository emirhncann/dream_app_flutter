import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Coin düşürme fonksiyonu
  Future<bool> deductCoins(int amount) async {
    try {
      final user = _auth.currentUser;
      if (user?.email != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user!.email)
            .get();

        if (userDoc.exists) {
          int currentCoins = userDoc.data()?['coin'] ?? 0;
          
          if (currentCoins < amount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Yetersiz coin! Gerekli coin: $amount')),
            );
            return false;
          }

          await _firestore
              .collection('users')
              .doc(user.email)
              .update({'coin': currentCoins - amount});
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Coin düşme hatası: $e');
      return false;
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
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

void yorumla(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1d0042), Color(0xFF644092)], // Arka plan rengi
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              height: 450,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // İlk Yorumcu için Card
                  InkWell(
                    onTap: () async {
                      bool success = await deductCoins(50);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Saniye Abla rüyanızı yorumluyor...')),
                        );
                        Navigator.pop(context); // Dialog'u kapat
                      }
                    },
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.pets, color: Color(0xFF6602ad)), // Saniye Abla'nın simgesi
                        title: Text(
                          'Saniye Abla Yorumlasın',
                          style: TextStyle(color: Color(0xFF6602ad), fontSize: 18),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on, color: Colors.amber),
                            Text(
                              ' 50',
                              style: TextStyle(color: Colors.amber, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text("Dilersen Profesyonel Yorumculara Yorumlat" ,style: TextStyle(color: Colors.white),),
                  // Ahmet'in Yorumlaması için Card
                Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('https://i.imgur.com/OvMZBs9.jpg'), // Ayşe'nin resmi
                      ),
                      title: Text(
                        'Ayşe Yorumlasın',
                        style: TextStyle(color: Color(0xFF6602ad), fontSize: 18),
                      ),
                      subtitle: Text(
                        '48 saat içerisinde',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on, color: Colors.amber),
                          Text(
                            ' 150',
                            style: TextStyle(color: Colors.amber, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Ayşe'nin Yorumlaması için Card
                  InkWell(
                    onTap: () async {
                      bool success = await deductCoins(150);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ayşe rüyanızı yorumluyor...')),
                        );
                        Navigator.pop(context); // Dialog'u kapat
                      }
                    },
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage('https://i.imgur.com/OvMZBs9.jpg'), // Ayşe'nin resmi
                        ),
                        title: Text(
                          'Ayşe Yorumlasın',
                          style: TextStyle(color: Color(0xFF6602ad), fontSize: 18),
                        ),
                        subtitle: Text(
                          '48 saat içerisinde',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on, color: Colors.amber),
                            Text(
                              ' 150',
                              style: TextStyle(color: Colors.amber, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sağ üst köşede kapatma butonu
            Positioned(
              right: 0.0,
              top: 0.0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop(); // Dialogu kapatır
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}


}
