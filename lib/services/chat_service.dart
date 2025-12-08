import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:fasalmitra/services/language_service.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  static const String _apiKey =
      'AIzaSyAksnmEFH9AcjFekrCzo9p4f0mSfc-Y_74'; // Secured in real app
  late GenerativeModel _model;
  ChatSession? _chatSession;

  void init() {
    // We will re-initialize the model/session when starting a chat to ensure language context is fresh
    // or we can pass language in system instruction.
  }

  Future<ChatSession> startChat() async {
    final langCode = LanguageService.instance.currentLanguage;
    final langName = LanguageService.supportedLanguages.firstWhere(
      (l) => l['code'] == langCode,
      orElse: () => {'label': 'English'},
    )['label']!;

    final systemInstruction = Content.system('''
You are **KrishiMitra**, a smart AI helper for farmers on the FasalMitra platform.

Your behavior rules:
1. Always answer in the language: $langName ($langCode).
2. Only answer questions related to:
   - Farming and agriculture
   - Crops, soil, fertilizers, seeds, pests, irrigation
   - Market prices and demand trend understanding
   - How to use the FasalMitra website
   - Selling oil seeds on the platform
   - Buying oil seeds as a processor / refinery
   - By-product prices and market insights
   - Logistics and marketplace processes
3. If the user asks something unrelated to farming or FasalMitra, politely decline.
4. Keep answers short, simple, and easy for farmers to understand.
5. Never give medical, legal, financial investment, or political advice.

Platform Information:
- FasalMitra is an online marketplace where farmers can sell their oil seeds with **zero commission**.
- Refiners and processors can buy oil seeds in large quantities directly from farmers.
- The platform removes middlemen and eliminates unnecessary commission costs.
- Processors can also view **AI-powered market predictions** for oil seed by-products to improve profits in exports.
- The goal is to empower both farmers and processors by increasing transparency and reducing exploitation.

Your job: Assist the user with farming-related questions and guide them through FasalMitra services clearly and politely.
''');

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: systemInstruction,
    );

    _chatSession = _model.startChat();
    return _chatSession!;
  }

  Future<String> sendMessage(String message) async {
    if (_chatSession == null) {
      await startChat();
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'Sorry, I could not understand that.';
    } catch (e) {
      return 'Error: Unable to connect to KrishiMitra. Details: $e';
    }
  }
}
