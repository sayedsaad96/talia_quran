class ArabicNormalizer {
  static String normalize(String text) {
    if (text.isEmpty) return text;

    String normalized = text;

    // Remove Arabic diacritics (Tashkeel)
    final tashkeelRegex = RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]');
    normalized = normalized.replaceAll(tashkeelRegex, '');

    // Normalize Alef variations to a bare Alef
    final alefRegex = RegExp(r'[أإآٱ]');
    normalized = normalized.replaceAll(alefRegex, 'ا');

    // Normalize Ya and Alif Maksura to simple Ya (or Alif Maksura, whichever is consistent)
    // We'll normalize to bare Ya so both match.
    final yaRegex = RegExp(r'[ىي]');
    normalized = normalized.replaceAll(yaRegex, 'ي');

    // Normalize Ta Marbuta to Ha or vice versa (usually spoken as Ha or Ta)
    // We map Ta Marbuta to Ha
    normalized = normalized.replaceAll('ة', 'ه');

    // Normalize waw with hamza
    normalized = normalized.replaceAll('ؤ', 'و');
    
    // Normalize ya with hamza
    normalized = normalized.replaceAll('ئ', 'ي');

    // Remove tatweel (kashida)
    normalized = normalized.replaceAll('\u0640', '');
    
    // Remove punctuation, zero-width spaces, and extra whitespace
    normalized = normalized.replaceAll(RegExp(r'[.,;؛؟!?\-\u200B\u200C\u200D\uFEFF]'), ' ');
    
    // Replace multiple spaces with a single space and trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }
}
