import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

class LanguageService extends ChangeNotifier {
  LanguageService._();

  static final LanguageService instance = LanguageService._();
  static const _prefsKey = 'app_language_v1';

  String _currentLanguage = 'hi';
  late SharedPreferences _prefs;
  final GoogleTranslator _translator = GoogleTranslator();

  // Cache for dynamic translations: {'hi': {'Hello': 'नमस्ते'}}
  final Map<String, Map<String, String>> _dynamicCache = {};
  // Set to track pending translations to avoid duplicate requests
  final Set<String> _pendingTranslations = {};

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final saved = prefs.getString(_prefsKey);
    if (saved != null && _strings.containsKey(saved)) {
      _currentLanguage = saved;
    }
  }

  String get currentLanguage => _currentLanguage;

  Future<void> changeLanguage(String code) async {
    if (!_strings.containsKey(code)) return;
    if (_currentLanguage == code) return;
    _currentLanguage = code;
    await _prefs.setString(_prefsKey, code);
    notifyListeners();
  }

  String t(String key) {
    // 1. Check hardcoded strings
    if (_strings[_currentLanguage]?.containsKey(key) ?? false) {
      return _strings[_currentLanguage]![key]!;
    }

    // 2. Check dynamic cache
    if (_dynamicCache[_currentLanguage]?.containsKey(key) ?? false) {
      return _dynamicCache[_currentLanguage]![key]!;
    }

    // 3. Fetch translation dynamically
    _fetchTranslation(key, _currentLanguage);

    // Return original key while loading
    return key;
  }

  Future<void> _fetchTranslation(String text, String targetLang) async {
    final cacheKey = '$targetLang:$text';
    if (_pendingTranslations.contains(cacheKey)) return;

    _pendingTranslations.add(cacheKey);

    try {
      final translation = await _translator.translate(text, to: targetLang);

      if (_dynamicCache[targetLang] == null) {
        _dynamicCache[targetLang] = {};
      }
      _dynamicCache[targetLang]![text] = translation.text;

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      print('Translation error for "$text" to $targetLang: $e');
    } finally {
      _pendingTranslations.remove(cacheKey);
    }
  }

  static List<Locale> get supportedLocales =>
      _strings.keys.map(Locale.new).toList();

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'hi', 'label': 'हिंदी'},
    {'code': 'mr', 'label': 'मराठी'},
    {'code': 'te', 'label': 'తెలుగు'},
    {'code': 'ta', 'label': 'தமிழ்'},
  ];
}

const Map<String, Map<String, String>> _strings = {
  'en': {
    'welcome': 'Welcome to',
    'appName': 'FasalMitra',
    'login': 'Login',
    'register': 'Register',
    'home': 'Home',
    'fullName': 'Full Name',
    'mobile': 'Mobile No.',
    'captcha': 'Captcha',
    'captchaText': 'Captcha Text',
    'sendOtp': 'Send OTP',
    'registerCta': 'Register',
    'newUser': 'New User? Register',
    'alreadyRegistered': 'Already Registered? Login',
    'enterOtp': 'Enter OTP',
    'otpPlaceholder': '••••••',
    'enterPhone': 'Enter Your Phone Number (with Country Code)',
    'otpSentPrefix': 'OTP Sent to',
    'captchaNotReady': 'Captcha Not Ready Yet',
    'captchaEnter': 'Enter Captcha Text',
    'aboutUs': 'About Us',
    'customerCare': 'Customer Care',
    'listProduct': 'List Product',
    'marketplace': 'Marketplace',
    'recentListings': 'Recent Listings',
    'searchByCategory': 'Search by Category',
    'qualityCheck': 'Quality Check / Test Product Quality',
    'searchSeeds': 'Search Seeds / Marketplace',
    'viewAll': 'View All',
    'buyNow': 'Buy Now',
    'qty': 'Qty',
    'processed': 'Processed',
    'unknownFarmer': 'Unknown Farmer',
    'seedPriceMarket': 'Seed Price Market',
    'sellOilseed': 'Sell Oilseed',
    'buyOilseed': 'Buy Oilseed',
    'myOrders': 'My Orders',
    'orderTracking': 'Order Tracking',
    'searchOilSeed': 'Search Oil Seed',
    'searchPlaceholder': 'Search for seeds, crops...',
    'recentPost': 'Recent Post',
    'menu': 'Menu',
    'usefulWebsites': 'Useful Websites',
    'pmKisan': 'PM Kisan Samman Nidhi',
    'pmFasalBima': 'PM Fasal Bima Yojana',
    'enam': 'e-NAM',
    'soilHealth': 'Soil Health Card',
  },
  'hi': {
    'welcome': 'आपका स्वागत है',
    'appName': 'फ़सलमित्र',
    'login': 'लॉगिन',
    'register': 'पंजीकरण',
    'home': 'होम',
    'fullName': 'पूरा नाम',
    'mobile': 'मोबाइल नंबर',
    'captcha': 'कैप्चा',
    'captchaText': 'कैप्चा टेक्स्ट',
    'sendOtp': 'ओटीपी भेजें',
    'registerCta': 'पंजीकरण करें',
    'newUser': 'नए उपयोगकर्ता? पंजीकरण करें',
    'alreadyRegistered': 'पहले से पंजीकृत? लॉगिन करें',
    'enterOtp': 'ओटीपी दर्ज करें',
    'otpPlaceholder': '••••••',
    'enterPhone': 'देश कोड सहित मोबाइल नंबर दर्ज करें',
    'otpSentPrefix': 'ओटीपी भेजा गया',
    'captchaNotReady': 'कैप्चा तैयार नहीं है',
    'captchaEnter': 'कैप्चा टेक्स्ट दर्ज करें',
    'aboutUs': 'हमारे बारे में',
    'customerCare': 'ग्राहक सेवा',
    'listProduct': 'उत्पाद सूचीबद्ध करें',
    'marketplace': 'बाज़ार',
    'recentListings': 'हाल की सूचियां',
    'searchByCategory': 'श्रेणी से खोजें',
    'qualityCheck': 'गुणवत्ता जांच / उत्पाद गुणवत्ता परीक्षण',
    'searchSeeds': 'बीज खोजें / बाज़ार',
    'viewAll': 'सभी देखें',
    'buyNow': 'अभी खरीदें',
    'qty': 'मात्रा',
    'processed': 'संसाधित',
    'unknownFarmer': 'अज्ञात किसान',
    'seedPriceMarket': 'बीज मूल्य बाज़ार',
    'sellOilseed': 'तिलहन बेचें',
    'buyOilseed': 'तिलहन खरीदें',
    'myOrders': 'मेरे ऑर्डर',
    'orderTracking': 'ऑर्डर ट्रैकिंग',
    'searchOilSeed': 'तिलहन खोजें',
    'searchPlaceholder': 'बीज, फसलें खोजें...',
    'recentPost': 'हालिया पोस्ट',
    'menu': 'मेनू',
    'usefulWebsites': 'उपयोगी वेबसाइटें',
    'pmKisan': 'पीएम किसान सम्मान निधि',
    'pmFasalBima': 'पीएम फसल बीमा योजना',
    'enam': 'ई-नाम (e-NAM)',
    'soilHealth': 'मृदा स्वास्थ्य कार्ड',
  },
  'mr': {
    'welcome': 'आपला स्वागत आहे',
    'appName': 'फसलमित्र',
    'login': 'लॉगिन',
    'register': 'नोंदणी',
    'home': 'मुख्यपृष्ठ',
    'fullName': 'संपूर्ण नाव',
    'mobile': 'मोबाइल क्रमांक',
    'captcha': 'कॅप्चा',
    'captchaText': 'कॅप्चा मजकूर',
    'sendOtp': 'ओटीपी पाठवा',
    'registerCta': 'नोंदणी करा',
    'newUser': 'नवीन वापरकर्ता? नोंदणी करा',
    'alreadyRegistered': 'आधीच नोंदणी केली? लॉगिन करा',
    'enterOtp': 'ओटीपी प्रविष्ट करा',
    'otpPlaceholder': '••••••',
    'enterPhone': 'कृपया देशकोडसह मोबाईल क्रमांक लिहा',
    'otpSentPrefix': 'ओटीपी पाठवला',
    'captchaNotReady': 'कॅप्चा तयार नाही',
    'captchaEnter': 'कॅप्चा मजकूर लिहा',
    'aboutUs': 'आमच्याबद्दल',
    'customerCare': 'ग्राहक सेवा',
    'listProduct': 'उत्पाद सूचीबद्ध करा',
    'marketplace': 'बाजार',
    'recentListings': 'अलीकडील सूची',
    'searchByCategory': 'श्रेणीनुसार शोधा',
    'qualityCheck': 'गुणवत्ता तपासणी / उत्पाद गुणवत्ता चाचणी',
    'searchSeeds': 'बीज शोधा / बाजार',
    'viewAll': 'सर्व पहा',
    'buyNow': 'आता खरेदी करा',
    'qty': 'प्रमाण',
    'processed': 'प्रक्रिया केलेले',
    'unknownFarmer': 'अज्ञात शेतकरी',
  },
  'te': {
    'welcome': 'స్వాగతం',
    'appName': 'ఫసల్మిత్ర',
    'login': 'లాగిన్',
    'register': 'నమోదు',
    'home': 'హోమ్',
    'fullName': 'పూర్తి పేరు',
    'mobile': 'మొబైల్ నం.',
    'captcha': 'క్యాప్చా',
    'captchaText': 'క్యాప్చా టెక్స్ట్',
    'sendOtp': 'ఓటీపీ పంపు',
    'registerCta': 'నమోదు చేయండి',
    'newUser': 'కొత్త వినియోగదారు? నమోదు',
    'alreadyRegistered': 'ఇప్పటికే నమోదయ్యారా? లాగిన్',
    'enterOtp': 'ఓటీపీ నమోదు చేయండి',
    'otpPlaceholder': '••••••',
    'enterPhone': 'దేశ కోడ్‌తో ఫోన్ నంబర్ ఇవ్వండి',
    'otpSentPrefix': 'ఓటీపీ పంపబడింది',
    'captchaNotReady': 'క్యాప్చా సిద్ధంగా లేదు',
    'captchaEnter': 'క్యాప్చా టెక్స్ట్ నమోదు చేయండి',
    'aboutUs': 'మా గురించి',
    'customerCare': 'కస్టమర్ కేర్',
    'listProduct': 'ఉత్పత్తిని జాబితా చేయండి',
    'marketplace': 'మార్కెట్',
    'recentListings': 'ఇటీవలి జాబితాలు',
    'searchByCategory': 'వర్గం ద్వారా శోధించండి',
    'qualityCheck': 'నాణ్యత తనిఖీ / ఉత్పత్తి నాణ్యత పరీక్ష',
    'searchSeeds': 'విత్తనాలు శోధించండి / మార్కెట్',
    'viewAll': 'అన్నీ చూడండి',
    'buyNow': 'ఇప్పుడే కొనండి',
    'qty': 'పరిమాణం',
    'processed': 'ప్రాసెస్ చేయబడింది',
    'unknownFarmer': 'తెలియని రైతు',
  },
  'ta': {
    'welcome': 'வரவேற்பு',
    'appName': 'பசல்மித்ரா',
    'login': 'உள்நுழைவு',
    'register': 'பதிவு',
    'home': 'முகப்பு',
    'fullName': 'முழு பெயர்',
    'mobile': 'கைபேசி எண்',
    'captcha': 'கேப்சா',
    'captchaText': 'கேப்சா உரை',
    'sendOtp': 'OTP அனுப்பு',
    'registerCta': 'பதிவு செய்யவும்',
    'newUser': 'புதிய பயனர்? பதிவு',
    'alreadyRegistered': 'ஏற்கனவே பதிவுசெய்தீர்களா? உள்நுழைக',
    'enterOtp': 'OTP ஐ உள்ளிடவும்',
    'otpPlaceholder': '••••••',
    'enterPhone': 'நாட்டு குறியுடன் கைபேசி எண்ணை உள்ளிடவும்',
    'otpSentPrefix': 'OTP அனுப்பப்பட்டது',
    'captchaNotReady': 'கேப்சா தயார் இல்லை',
    'captchaEnter': 'கேப்சா உரை உள்ளிடவும்',
    'aboutUs': 'எங்களைப் பற்றி',
    'customerCare': 'வாடிக்கையாளர் பராமரிப்பு',
    'listProduct': 'தயாரிப்பை பட்டியலிடு',
    'marketplace': 'சந்தை',
    'recentListings': 'சமீபத்திய பட்டியல்கள்',
    'searchByCategory': 'வகையால் தேடு',
    'qualityCheck': 'தர சோதனை / தயாரிப்பு தரம் சோதனை',
    'searchSeeds': 'விதைகளைத் தேடு / சந்தை',
    'viewAll': 'அனைத்தையும் பார்க்க',
    'buyNow': 'இப்போது வாங்கவும்',
    'qty': 'அளவு',
    'processed': 'செயலாக்கப்பட்டது',
    'unknownFarmer': 'தெரியாத விவசாயி',
  },
};
