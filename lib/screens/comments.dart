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
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return;

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('yorumlar')
          .orderBy('tarih', descending: true)
          .get();

      setState(() {
        _comments = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final timerEnd = data['timerEnd'] as Timestamp;
          _readyComments[doc.id] = DateTime.now().isAfter(timerEnd.toDate());
          return {
            'id': doc.id,
            'dream': data['ruya'] ?? '',
            'interpretation': data['yorum'] ?? '',
            'timestamp': data['tarih'] ?? Timestamp.now(),
            'timerEnd': timerEnd,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Yorumlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
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
    final readyTime = (comment['timerEnd'] as Timestamp).toDate();
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
    final timestamp = comment['timestamp'] as Timestamp;
    final timerEnd = comment['timerEnd'] as Timestamp;
    final date = timestamp.toDate();
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);

    void _showWaitDialog() {
      final now = DateTime.now();
      final end = timerEnd.toDate();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _comments.isEmpty
                ? Center(
                    child: Text(
                      'Henüz rüya yorumu bulunmuyor.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) => _buildCommentCard(_comments[index]),
                  ),
      ),
    );
  }
}
