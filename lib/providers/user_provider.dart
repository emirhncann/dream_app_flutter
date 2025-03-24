import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _userDataSubscription;

  String? _firstName;
  String? _lastName;
  String? _email;
  String? _birthDate;
  String? _gender;
  int _coins = 0;
  int _dreamCount = 0;
  int _spentCoins = 0;
  bool _isLoggedIn = false;

  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get birthDate => _birthDate;
  String? get gender => _gender;
  int get coins => _coins;
  int get dreamCount => _dreamCount;
  int get spentCoins => _spentCoins;
  bool get isLoggedIn => _isLoggedIn;

  UserProvider() {
    _setupUserDataListener();
  }

  void _setupUserDataListener() {
    final user = _auth.currentUser;
    if (user?.email != null) {
      _userDataSubscription = _firestore
          .collection('users')
          .doc(user!.email)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          print('Firestore Data Updated: $data'); // Debug için

          _firstName = data['first_name'];
          _lastName = data['last_name'];
          _birthDate = data['dg'];
          _gender = data['gender'];
          _coins = data['coin'] ?? 0;
          _dreamCount = data['dreamCount'] ?? 0;
          _spentCoins = data['spentCoins'] ?? 0;
          _isLoggedIn = true;
          _email = user.email;

          print('User Data Updated:'); // Debug için
          print('First Name: $_firstName');
          print('Last Name: $_lastName');
          print('Birth Date: $_birthDate');
          print('Gender: $_gender');
          print('Coins: $_coins');
          print('Dream Count: $_dreamCount');
          print('Spent Coins: $_spentCoins');

          notifyListeners();
        }
      }, onError: (error) {
        print('Veri dinleme hatası: $error');
      });
    }
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  // Public loadUserData metodu
  Future<void> loadUserData() async {
    await _loadUserData();
  }

  // Coin stream'ini dinle
  Stream<int> getCoinStream() {
    final user = _auth.currentUser;
    if (user?.email != null) {
      return _firestore
          .collection('users')
          .doc(user!.email)
          .snapshots()
          .map((snapshot) {
            final coins = snapshot.data()?['coin'] ?? 0;
            _coins = coins; // Local state'i güncelle
            return coins;
          });
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

          // Firebase'de coin'i güncelle
          await _firestore
              .collection('users')
              .doc(user.email)
              .update({
                'coin': currentCoins - amount,
                'spentCoins': FieldValue.increment(amount),
                'lastUpdated': FieldValue.serverTimestamp(),
              });
          
          // Local state'i güncelle
          _coins = currentCoins - amount;
          _spentCoins += amount;
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

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _email = user.email;
        
        final userData = await _firestore
            .collection('users')
            .doc(user.email)
            .get();

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>;
          print('Firestore Data: $data'); // Debug için veriyi yazdır
          
          _firstName = data['first_name'];
          _lastName = data['last_name'];
          _birthDate = data['dg'];
          _gender = data['gender'];
          _coins = data['coin'] ?? 0;
          _dreamCount = data['dreamCount'] ?? 0;
          _spentCoins = data['spentCoins'] ?? 0;
          _isLoggedIn = true;
          
          print('Loaded User Data:'); // Debug için yüklenen verileri yazdır
          print('First Name: $_firstName');
          print('Last Name: $_lastName');
          print('Birth Date: $_birthDate');
          print('Gender: $_gender');
          print('Coins: $_coins');
          print('Dream Count: $_dreamCount');
          print('Spent Coins: $_spentCoins');
          
          notifyListeners();
        } else {
          print('User document does not exist in Firestore');
        }
      }
    } catch (e) {
      print('Kullanıcı verileri yüklenirken hata oluştu: $e');
    }
  }

  Future<void> updateUserData({
    String? firstName,
    String? lastName,
    String? birthDate,
    String? gender,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final updates = <String, dynamic>{};
        
        if (firstName != null) {
          updates['first_name'] = firstName;
          _firstName = firstName;
        }
        if (lastName != null) {
          updates['last_name'] = lastName;
          _lastName = lastName;
        }
        if (birthDate != null) {
          updates['dg'] = birthDate;
          _birthDate = birthDate;
        }
        if (gender != null) {
          updates['gender'] = gender;
          _gender = gender;
        }

        if (updates.isNotEmpty) {
          updates['lastUpdated'] = FieldValue.serverTimestamp();
          await _firestore
              .collection('users')
              .doc(user.email)
              .update(updates);
          
          notifyListeners();
        }
      }
    } catch (e) {
      print('Kullanıcı verileri güncellenirken hata oluştu: $e');
    }
  }

  Future<void> updateCoins(int amount) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.email)
            .get();

        if (userDoc.exists) {
          int currentCoins = userDoc.data()?['coin'] ?? 0;
          
          // Firebase'de coin'i güncelle
          await _firestore
              .collection('users')
              .doc(user.email)
              .update({
                'coin': currentCoins + amount,
                'lastUpdated': FieldValue.serverTimestamp(),
              });
          
          // Local state'i güncelle
          _coins = currentCoins + amount;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Coin bakiyesi güncellenirken hata oluştu: $e');
    }
  }

  Future<void> incrementDreamCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _dreamCount++;
        
        await _firestore
            .collection('users')
            .doc(user.email)
            .update({
          'dreamCount': _dreamCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        notifyListeners();
      }
    } catch (e) {
      print('Rüya sayısı güncellenirken hata oluştu: $e');
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