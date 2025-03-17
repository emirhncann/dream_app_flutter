import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';

class DreamInterpretations extends StatefulWidget {
  const DreamInterpretations({super.key});

  @override
  State<DreamInterpretations> createState() => _DreamInterpretationsState();
}

class _DreamInterpretationsState extends State<DreamInterpretations> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 1;
  
  // Sayfalama için değişkenler
  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  List<DocumentSnapshot> _yorumlar = [];

  @override
  void initState() {
    super.initState();
    _getYorumlar();
  }

  Future<void> _getYorumlar() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return;

      Query query = _firestore
          .collection('users')
          .doc(userEmail)
          .collection('yorumlar')
          .orderBy('tarih', descending: true)
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();
      
      if (querySnapshot.docs.length < _limit) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _yorumlar.addAll(querySnapshot.docs);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Veri çekme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: _yorumlar.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        'Henüz yorum yapılmış rüya bulunmuyor',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _yorumlar.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _yorumlar.length) {
                          return _buildLoadMoreButton();
                        }

                        final data = _yorumlar[index].data() as Map<String, dynamic>;
                        final timestamp = data['tarih'] as Timestamp;
                        final formattedDate = '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF1d0042), Color(0xFF644092)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Rüya',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Card(
                                            color: Colors.white.withOpacity(0.9),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Text(
                                                data['ruya'] ?? '',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            'Yorum',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Card(
                                            color: Colors.white.withOpacity(0.9),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Text(
                                                data['yorum'] ?? '',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF6602ad),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 32,
                                                  vertical: 12,
                                                ),
                                              ),
                                              child: Text(
                                                'Kapat',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Color(0xFFE8E1F3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.nights_stay, color: Color(0xFF6602ad)),
                                            SizedBox(width: 8),
                                            Text(
                                              data['yorumcu'] ?? '',
                                              style: TextStyle(
                                                color: Color(0xFF6602ad),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      data['ruya'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildLoadMoreButton() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (!_hasMore) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Başka yorum bulunmuyor',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _getYorumlar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6602ad),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Daha Fazla Yükle',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
} 