import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:flutter/material.dart';

class DreamComments extends StatefulWidget {
  @override
  _DreamCommentsState createState() => _DreamCommentsState();
}

class _DreamCommentsState extends State<DreamComments> {
  int _selectedIndex = 0;

  // Örnek rüya yorumları
  final List<String> comments = [
    "18.10.2024 Tarihli Rüya","18.10.2024 Tarihli Rüya","18.10.2024 Tarihli Rüya","18.10.2024 Tarihli Rüya",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Yeni sayfaya gitmek için fonksiyon
  void _navigateToDetail(BuildContext context, String comment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DreamDetailPage(comment: comment),
      ),
    );
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
        
        child: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: ListView.builder(
            
            itemCount: comments.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _navigateToDetail(context, comments[index]); // Yeni sayfaya yönlendirme
                },
                
                child: Card(
                  margin: EdgeInsets.all(8),
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      comments[index],
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            },
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

// Yeni sayfa: DreamDetailPage
class DreamDetailPage extends StatelessWidget {
  final String comment;

  DreamDetailPage({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rüya Yorumu Detayı'),
        backgroundColor: Color(0xFF6602ad), // AppBar rengi
      ),
      body: Container(
        padding: EdgeInsets.all(16),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 20), // Boşluk ekleyelim
              Text(
                "Bu rüya yorumu, çeşitli kaynaklardan derlenmiştir. Rüyada su görmek genellikle duyguların ifade şeklidir, ancak daha derin anlamlar da içerebilir.",
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
              ),
              SizedBox(height: 10),
              Text(
                "Detaylı inceleme için daha fazla bilgi eklenebilir.",
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
