import 'package:dream_app_flutter/models/myappbar.dart';
import 'package:dream_app_flutter/models/mynavbar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class DreamComments extends StatefulWidget {
  @override
  _DreamCommentsState createState() => _DreamCommentsState();
}

class _DreamCommentsState extends State<DreamComments> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _comments = [];
  Map<String, bool> _readyComments = {};
  Timer? _checkReadyTimer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadComments();
    // Her 10 saniyede bir yorumların hazır olup olmadığını kontrol et
    _checkReadyTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkReadyComments();
    });
  }

  @override
  void dispose() {
    _checkReadyTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user?.email == null) {
        throw Exception('Lütfen önce giriş yapın.');
      }

      // Rüya yorumlarını yükle
      final dreamsQuery = await _firestore
          .collection('users')
          .doc(user!.email)
          .collection('dreams')
          .orderBy('date', descending: true)
          .get();

      // Astroloji yorumlarını yükle
      final astrologyQuery = await _firestore
          .collection('users')
          .doc(user.email)
          .collection('astrology')
          .orderBy('date', descending: true)
          .get();

      final List<Map<String, dynamic>> allComments = [];

      // Rüya yorumlarını ekle
      for (var doc in dreamsQuery.docs) {
        final data = doc.data();
        allComments.add({
          ...data,
          'id': doc.id,
          'type': 'dream',
          'date': data['date'] as Timestamp,
        });
      }

      // Astroloji yorumlarını ekle
      for (var doc in astrologyQuery.docs) {
        final data = doc.data();
        allComments.add({
          ...data,
          'id': doc.id,
          'type': 'astrology',
          'date': data['date'] as Timestamp,
          'reading': data['reading'] ?? '',
        });
      }

      // Tüm yorumları tarihe göre sırala
      allComments.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

      setState(() {
        _comments = allComments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkReadyComments() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return;

    for (var comment in _comments) {
      String commentId = comment['id'];
      if (_readyComments[commentId] != true) {
        final timerEnd = comment['timerEnd'] as Timestamp;
        if (DateTime.now().isAfter(timerEnd.toDate())) {
          setState(() {
            _readyComments[commentId] = true;
          });
        }
      }
    }
  }

  void _startCommentTimer(String commentId) {
    final comment = _comments.firstWhere((c) => c['id'] == commentId);
    final readyTime = (comment['date'] as Timestamp).toDate();
    final remainingTime = readyTime.difference(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1d0042),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF6602ad), width: 2),
                ),
                child: Column(
                  children: [
                    Lottie.asset(
                      'assets/gif/loading.json',
                      width: 150,
                      height: 150,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Rüya Yorumunuz Hazırlanıyor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    StreamBuilder<int>(
                      stream: Stream.periodic(
                        Duration(seconds: 1),
                        (i) => remainingTime.inSeconds - i,
                      ).take(remainingTime.inSeconds + 1),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox();
                        
                        final minutes = (snapshot.data! ~/ 60);
                        final seconds = (snapshot.data! % 60);
                        
                        return Column(
                          children: [
                            Text(
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Rüyanız yapay zeka tarafından\nJung psikolojisine göre yorumlanıyor...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _timer = Timer(remainingTime, () {
      Navigator.of(context).pop(); // Dialog'u kapat
      setState(() {
        _readyComments[commentId] = true;
      });
      _updateCommentStatus(commentId);
    });
  }

  Future<void> _updateCommentStatus(String commentId) async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('yorumlar')
          .doc(commentId)
          .update({
        'isTimerActive': false,
      });
    } catch (e) {
      print('Yorum durumu güncellenirken hata: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final isReady = _readyComments[comment['id']] ?? false;
    final interpretation = comment['interpretation'] ?? '';
    final timestamp = comment['date'] as Timestamp;
    final date = timestamp.toDate();
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);

    void _showWaitDialog() {
      final now = DateTime.now();
      final end = timestamp.toDate();
      if (now.isBefore(end)) {
        final remaining = end.difference(now);
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1d0042),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Color(0xFF6602ad), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/gif/loading.json',
                    width: 150,
                    height: 150,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Rüya Yorumunuza Ulaşmak İçin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${minutes}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'bekleyin veya',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAd(comment['id']);
                    },
                    icon: Icon(Icons.play_circle_outline),
                    label: Text('Reklam İzleyerek Hemen Açın'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 45),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Beklemeye Devam Et',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            if (!isReady) {
              _showWaitDialog();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rüya:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  comment['dream'] ?? '',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Rüya Yorumu:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (isReady)
                  Text(
                    interpretation,
                    style: TextStyle(color: Colors.white),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Yorumu görmek için tıklayın',
                          style: TextStyle(
                            color: Colors.amber,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAd(String commentId) async {
    // TODO: Burada reklam gösterilecek
    // Reklam başarıyla tamamlandığında:
    setState(() {
      _readyComments[commentId] = true;
    });
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
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
                    'Yorumlarım',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rüya ve astroloji yorumların',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Yorum Listesi
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : _comments.isEmpty
                      ? Center(
                          child: Text(
                            'Henüz yorumun yok',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final isAstrology = comment['type'] == 'astrology';
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF3D2C8D).withOpacity(0.95),
                                      Color(0xFF1A1034).withOpacity(0.95),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isAstrology ? Icons.auto_awesome : Icons.nightlight_round,
                                            color: isAstrology ? Colors.amber : Colors.white,
                                            size: 24,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            isAstrology ? 'Astroloji Yorumu' : 'Rüya Yorumu',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            _formatDate(comment['date'] as Timestamp),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      isAstrology
                                          ? Column(
                                              children: comment['reading'].split('\n\n').map((section) {
                                                if (section.contains('**')) {
                                                  return Container(
                                                    width: double.infinity,
                                                    margin: EdgeInsets.only(top: 16, bottom: 8),
                                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Color(0xFF5D4B9E).withOpacity(0.3),
                                                          Color(0xFF3D2C8D).withOpacity(0.3),
                                                        ],
                                                        begin: Alignment.centerLeft,
                                                        end: Alignment.centerRight,
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.amber.withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      section.replaceAll('**', ''),
                                                      style: TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        height: 1.6,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  return Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                                    child: Text(
                                                      section,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        height: 1.6,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }).toList(),
                                            )
                                          : (_readyComments[comment['id']] ?? false)
                                              ? Text(
                                                  comment['interpretation'] ?? 'Yorum hazırlanıyor...',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    height: 1.6,
                                                  ),
                                                )
                                              : InkWell(
                                                  onTap: () {
                                                    final now = DateTime.now();
                                                    final end = (comment['date'] as Timestamp).toDate();
                                                    if (now.isBefore(end)) {
                                                      final remaining = end.difference(now);
                                                      final minutes = remaining.inMinutes;
                                                      final seconds = remaining.inSeconds % 60;
                                                      
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (context) => Dialog(
                                                          backgroundColor: Colors.transparent,
                                                          child: Container(
                                                            padding: EdgeInsets.all(20),
                                                            decoration: BoxDecoration(
                                                              color: Color(0xFF1d0042),
                                                              borderRadius: BorderRadius.circular(15),
                                                              border: Border.all(color: Color(0xFF6602ad), width: 2),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Lottie.asset(
                                                                  'assets/gif/loading.json',
                                                                  width: 150,
                                                                  height: 150,
                                                                ),
                                                                SizedBox(height: 20),
                                                                Text(
                                                                  'Rüya Yorumunuza Ulaşmak İçin',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 18,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 10),
                                                                Text(
                                                                  '${minutes}:${seconds.toString().padLeft(2, '0')}',
                                                                  style: TextStyle(
                                                                    color: Colors.amber,
                                                                    fontSize: 24,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 10),
                                                                Text(
                                                                  'bekleyin veya',
                                                                  style: TextStyle(
                                                                    color: Colors.white70,
                                                                    fontSize: 14,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 20),
                                                                ElevatedButton.icon(
                                                                  onPressed: () {
                                                                    Navigator.pop(context);
                                                                    _showAd(comment['id']);
                                                                  },
                                                                  icon: Icon(Icons.play_circle_outline),
                                                                  label: Text('Reklam İzleyerek Hemen Açın'),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: Colors.amber,
                                                                    foregroundColor: Colors.black,
                                                                    minimumSize: Size(double.infinity, 45),
                                                                  ),
                                                                ),
                                                                SizedBox(height: 10),
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(context),
                                                                  child: Text(
                                                                    'Beklemeye Devam Et',
                                                                    style: TextStyle(color: Colors.white70),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(vertical: 8),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.lock_clock, color: Colors.amber),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Yorumu görmek için tıklayın',
                                                          style: TextStyle(
                                                            color: Colors.amber,
                                                            fontStyle: FontStyle.italic,
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
}
