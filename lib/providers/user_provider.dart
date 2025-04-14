import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';

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
  String? _inviteCode;

  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get birthDate => _birthDate;
  String? get gender => _gender;
  int get coins => _coins;
  int get dreamCount => _dreamCount;
  int get spentCoins => _spentCoins;
  bool get isLoggedIn => _isLoggedIn;
  String? get inviteCode => _inviteCode;

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
          _inviteCode = data['invite_code'] as String?;

          print('User Data Updated:'); // Debug için
          print('First Name: $_firstName');
          print('Last Name: $_lastName');
          print('Birth Date: $_birthDate');
          print('Gender: $_gender');
          print('Coins: $_coins');
          print('Dream Count: $_dreamCount');
          print('Spent Coins: $_spentCoins');
          print('Invite Code: $_inviteCode');

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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _firstName = data['first_name'] as String?;
          _lastName = data['last_name'] as String?;
          _email = data['email'] as String?;
          _gender = data['gender'] as String?;
          _birthDate = data['birth_date'] as String?;
          _coins = data['coins'] as int? ?? 0;
          _inviteCode = data['invite_code'] as String?;
          _dreamCount = data['dream_count'] as int? ?? 0;
          _spentCoins = data['spent_coins'] as int? ?? 0;
          
          // Eğer davet kodu yoksa oluştur
          if (_inviteCode == null) {
            await _generateInviteCode(user.uid);
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      print('Kullanıcı verileri yüklenirken hata oluştu: $e');
    }
  }

  // Davet kodu oluşturma
  Future<void> _generateInviteCode(String userId) async {
    try {
      // Benzersiz bir davet kodu oluştur (8 haneli)
      final random = Random();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final code = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
      
      // Firestore'a kaydet
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'invite_code': code,
        'invite_code_created_at': FieldValue.serverTimestamp(),
      });
      
      _inviteCode = code;
      notifyListeners();
      
      print('Yeni davet kodu oluşturuldu: $code');
    } catch (e) {
      print('Davet kodu oluşturulurken hata oluştu: $e');
    }
  }

  // Davet kodunu kullanma
  Future<bool> useInviteCode(String code) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Davet kodunu kullanan kullanıcının bilgilerini güncelle
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'used_invite_code': code,
        'coins': FieldValue.increment(100), // Davet kodu kullanana 100 coin ver
      });

      // Davet kodunu oluşturan kullanıcıya da 100 coin ver
      final inviterQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('invite_code', isEqualTo: code)
          .get();

      if (inviterQuery.docs.isNotEmpty) {
        final inviterId = inviterQuery.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(inviterId).update({
          'coins': FieldValue.increment(100),
        });
      }

      _coins += 100;
      notifyListeners();
      return true;
    } catch (e) {
      print('Davet kodu kullanılırken hata oluştu: $e');
      return false;
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