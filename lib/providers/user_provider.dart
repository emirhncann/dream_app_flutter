import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  int _credits = 0;
  String? _email;
  bool _isLoggedIn = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int get credits => _credits;
  String? get email => _email;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> initUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadUserData(currentUser.uid);
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _firestore.collection('users').doc(uid).get();
      if (userData.exists) {
        _credits = userData.data()?['credits'] ?? 0;
        _email = userData.data()?['email'];
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      print('Veri yükleme hatası: $e');
    }
  }

  Future<void> updateCredits(int newCredits) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'credits': newCredits,
        });
        _credits = newCredits;
        notifyListeners();
      }
    } catch (e) {
      print('Kredi güncelleme hatası: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _credits = 0;
      _email = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      print('Çıkış hatası: $e');
    }
  }
} 