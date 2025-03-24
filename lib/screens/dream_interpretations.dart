import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'dart:async';

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
  Timer? _timer;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _getYorumlar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DocumentSnapshot lastYorum) {
    _timer?.cancel();
    
    final data = lastYorum.data() as Map<String, dynamic>;
    final timerEnd = data['timerEnd'] as Timestamp;
    final isTimerActive = data['isTimerActive'] as bool;
    
    if (!isTimerActive) {
      _remainingTime = 0;
      return;
    }

    final now = DateTime.now();
    final endTime = timerEnd.toDate();
    _remainingTime = endTime.difference(now).inSeconds;

    if (_remainingTime <= 0) {
      _updateTimerStatus(lastYorum.id);
      _remainingTime = 0;
      return;
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          timer.cancel();
          _updateTimerStatus(lastYorum.id);
        }
      });
    });
  }

  Future<void> _updateTimerStatus(String yorumId) async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return;

      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('yorumlar')
          .doc(yorumId)
          .update({
        'isTimerActive': false
      });
    } catch (e) {
      print('Timer durumu güncellenirken hata: $e');
    }
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
        
        // Sadece en son yorum için timer'ı başlat
        if (_yorumlar.isNotEmpty) {
          _startTimer(_yorumlar.first);
        }
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

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

                        final doc = _yorumlar[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = data['tarih'] as Timestamp;
                        final formattedDate = '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
                        final isTimerActive = data['isTimerActive'] as bool;

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
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
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Rüya Yorumu',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Card(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Rüyan:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  data['ruya'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Yorum:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  data['yorum'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(),
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
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (index == 0 && isTimerActive && _remainingTime > 0)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            _formatTime(_remainingTime),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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