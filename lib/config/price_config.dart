class PriceConfig {
  // Başlangıç coin miktarı
  static const int INITIAL_COINS = 500;

  // İşlem maliyetleri
  static const int DREAM_INTERPRETATION_COST = 100;
  static const int ASTROLOGY_READING_COST = 100;
  static const int VOICE_TO_DREAM_COST = 35;

  // Coin kazanma yöntemleri
  static const int WATCH_AD_REWARD = 50;

  // Coin kontrolü
  static bool hasEnoughCoins(int userCoins, int cost) {
    return userCoins >= cost;
  }

  // Coin mesajları
  static String getInsufficientCoinsMessage(int cost) {
    return 'Bu işlem için $cost coin gerekiyor. Coin kazanmak için reklam izleyebilirsiniz.';
  }

  // Coin işlem açıklamaları
  static const Map<String, String> TRANSACTION_DESCRIPTIONS = {
    'dream_interpretation': 'Rüya Yorumu',
    'astrology_reading': 'Astroloji Yorumu',
    'voice_to_dream': 'Sesli Rüya Kaydı',
    'watch_ad': 'Reklam İzleme Ödülü',
    'initial_coins': 'Hoşgeldin Bonusu',
  };
} 