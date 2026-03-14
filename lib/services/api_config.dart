class ApiConfig {
  static const String wordsApiBaseUrl = 'https://wordsapiv1.p.rapidapi.com/words/';
  static const String wordsApiHost = 'wordsapiv1.p.rapidapi.com';

  // Configure with:
  // flutter run --dart-define=RAPIDAPI_KEY=your_key_here
  static const String rapidApiKey = String.fromEnvironment('RAPIDAPI_KEY');

  static bool get hasRapidApiKey =>
      rapidApiKey.isNotEmpty && rapidApiKey != 'YOUR_RAPIDAPI_KEY';
}
