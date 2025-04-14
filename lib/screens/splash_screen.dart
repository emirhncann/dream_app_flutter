import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  
  bool _isLogin = false;
  bool _isLoading = false;
  String? _gender;
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  int _currentStep = 0;
  String? _referrerEmail;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        height: size.height,
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isSmallScreen ? 10 : 20),
                  // Logo ve Animasyon
                  Center(
                    child: Lottie.asset(
                      'assets/gif/bulut.json',
                      width: isSmallScreen ? 140 : 180,
                      height: isSmallScreen ? 140 : 180,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 20),
                  // Başlık
                  Text(
                    'Rüya Yorumları',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  Text(
                    'Rüyalarınızı yapay zeka ile yorumlayın',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 40),
                  // Kayıt/Giriş Formu
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_currentStep == 0) ...[
                          if (!_isLogin) ...[
                            // Referans kodu alanı
                            TextFormField(
                              controller: _referralCodeController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                hintText: 'Referans Kodu (Opsiyonel)',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.card_giftcard, color: Colors.white),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                          ],
                          // E-posta alanı
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              hintText: 'E-posta',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.email, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'E-posta gerekli';
                              }
                              if (!value.contains('@')) {
                                return 'Geçerli bir e-posta adresi girin';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          // Şifre alanı
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              hintText: 'Şifre',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.lock, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre gerekli';
                              }
                              if (value.length < 6) {
                                return 'Şifre en az 6 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_currentStep == 1) ...[
                          // Ad alanı
                          TextFormField(
                            controller: _firstNameController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              hintText: 'Adınız',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.person, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ad gerekli';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          // Soyad alanı
                          TextFormField(
                            controller: _lastNameController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              hintText: 'Soyadınız',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Soyad gerekli';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_currentStep == 2) ...[
                          // Cinsiyet seçimi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGenderButton(
                                icon: Icons.female,
                                color: Colors.pink,
                                value: 'kız',
                                tooltip: 'Kız',
                              ),
                              SizedBox(width: 32),
                              _buildGenderButton(
                                icon: Icons.male,
                                color: Colors.blue,
                                value: 'erkek',
                                tooltip: 'Erkek',
                              ),
                            ],
                          ),
                        ],
                        if (_currentStep == 3) ...[
                          // Doğum tarihi seçimi
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                locale: const Locale('tr', 'TR'),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: Color(0xFF6602ad),
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF1d0042),
                                        onSurface: Colors.white,
                                      ),
                                      dialogBackgroundColor: Color(0xFF1d0042),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _birthDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _birthDate != null
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    _birthDate != null
                                        ? DateFormat('dd.MM.yyyy', 'tr_TR').format(_birthDate!)
                                        : 'Doğum Tarihi',
                                    style: TextStyle(
                                      color: _birthDate != null
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          // Doğum saati seçimi
                          InkWell(
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: Color(0xFF6602ad),
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF1d0042),
                                        onSurface: Colors.white,
                                      ),
                                      dialogBackgroundColor: Color(0xFF1d0042),
                                    ),
                                    child: MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        alwaysUse24HourFormat: true,
                                      ),
                                      child: child!,
                                    ),
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _birthTime = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _birthTime != null
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    _birthTime != null
                                        ? _birthTime!.format(context).replaceAll('AM', '').replaceAll('PM', '').trim()
                                        : 'Doğum Saati (Opsiyonel)',
                                    style: TextStyle(
                                      color: _birthTime != null
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          // Doğum yeri
                          TextFormField(
                            controller: _birthPlaceController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              hintText: 'Doğum Yeri (Opsiyonel)',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.location_on, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        // İleri/Kayıt Ol butonu
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6602ad),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 24 : 32,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: isSmallScreen ? 16 : 20,
                                  height: isSmallScreen ? 16 : 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _getButtonText(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Giriş/Kayıt değiştirme butonu
                        if (_currentStep == 0)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin ? 'Hesabın yok mu? Kayıt ol' : 'Zaten üye misin? Giriş yap',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton({
    required IconData icon,
    required Color color,
    required String value,
    required String tooltip,
  }) {
    final isSelected = _gender == value;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _gender = value;
          });
        },
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? color : Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_isLogin) return 'Giriş Yap';
    switch (_currentStep) {
      case 0:
        return 'İleri';
      case 1:
        return 'İleri';
      case 2:
        return _gender == null ? 'Cinsiyet Seç' : 'İleri';
      case 3:
        return _birthDate == null ? 'Doğum Tarihi Seç' : 'Kayıt Ol';
      default:
        return 'İleri';
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    if (_isLogin) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });

        try {
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Giriş başarısız: ${e.toString()}')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
      return;
    }

    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        // Referans kodunu kontrol et
        if (_referralCodeController.text.isNotEmpty) {
          try {
            final referralQuery = await _firestore
                .collection('users')
                .where('referral_code', isEqualTo: _referralCodeController.text)
                .get();

            if (referralQuery.docs.isNotEmpty) {
              _referrerEmail = referralQuery.docs.first.get('email');
            }
          } catch (e) {
            print('Referans kodu kontrolünde hata: $e');
          }
        }
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep = 2;
        });
      }
    } else if (_currentStep == 2) {
      if (_gender != null) {
        setState(() {
          _currentStep = 3;
        });
      }
    } else if (_currentStep == 3) {
      if (_birthDate != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          // Referans kodu oluştur
          final referralCode = _generateReferralCode();

          // Kullanıcı verilerini kaydet
          await _firestore.collection('users').doc(userCredential.user!.email).set({
            'email': userCredential.user!.email,
            'first_name': _firstNameController.text,
            'last_name': _lastNameController.text,
            'gender': _gender,
            'dg': DateFormat('dd.MM.yyyy').format(_birthDate!),
            'birth_time': _birthTime != null ? _birthTime!.format(context) : null,
            'birth_place': _birthPlaceController.text.isNotEmpty ? _birthPlaceController.text : null,
            'coin': 100,
            'dreamCount': 0,
            'spentCoins': 0,
            'referral_code': referralCode,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Referans veren kullanıcıya bonus coin ver
          if (_referrerEmail != null) {
            await _firestore.collection('users').doc(_referrerEmail).update({
              'coin': FieldValue.increment(50), // Referans veren kullanıcıya 50 coin bonus
            });
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kayıt başarısız: ${e.toString()}')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
} 