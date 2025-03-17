import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _coins = 0;
  String? _email;
  bool _isLoggedIn = false;

  int get coins => _coins;
  String? get email => _email;
  bool get isLoggedIn => _isLoggedIn;

  // Coin stream'ini dinle
  Stream<int> getCoinStream() {
    final user = _auth.currentUser;
    if (user?.email != null) {
      return _firestore
          .collection('users')
          .doc(user!.email)
          .snapshots()
          .map((snapshot) => snapshot.data()?['coin'] ?? 0);
    }
    return Stream.value(0);
  }

  // Coin düşürme işlemi
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
            return false;
          }

          await _firestore
              .collection('users')
              .doc(user.email)
              .update({'coin': currentCoins - amount});
          
          _coins = currentCoins - amount;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Coin düşme hatası: $e');
      return false;
    }
  }

  // Kullanıcı bilgilerini yükle
  Future<void> loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user?.email != null) {
        final userData = await _firestore
            .collection('users')
            .doc(user!.email)
            .get();

        if (userData.exists) {
          _coins = userData.data()?['coin'] ?? 0;
          _email = userData.data()?['email'];
          _isLoggedIn = true;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Kullanıcı bilgisi yükleme hatası: $e');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _coins = 0;
      _email = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      print('Çıkış hatası: $e');
    }
  }
} 