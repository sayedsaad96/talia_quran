class ArabicNormalizer {
  static String normalize(String text) {
    if (text.isEmpty) return text;

    String normalized = text;

    // Replace Uthmani marks with their letter equivalents
    normalized = normalized.replaceAll('\u0670', 'ا'); // Dagger Alef -> Alef
    normalized = normalized.replaceAll('\u06E5', 'و'); // Small Waw
    normalized = normalized.replaceAll('\u06E6', 'ي'); // Small Yaa

    // Remove Arabic diacritics (Tashkeel)
    final tashkeelRegex = RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED]');
    normalized = normalized.replaceAll(tashkeelRegex, '');

    // Normalize letters
    final alefRegex = RegExp(r'[أإآٱ]');
    normalized = normalized.replaceAll(alefRegex, 'ا');

    final yaRegex = RegExp(r'[ىيئ]');
    normalized = normalized.replaceAll(yaRegex, 'ي');

    normalized = normalized.replaceAll('ة', 'ه');
    normalized = normalized.replaceAll('ؤ', 'و');
    normalized = normalized.replaceAll('\u0640', '');

    // Phonetic STT normalizations (STT outputs Imla'i, we map it to match our phonetically expanded Uthmani)
    normalized = normalized.replaceAll('الرحمن', 'الرحمان');
    normalized = normalized.replaceAll('هذا', 'هاذا');
    normalized = normalized.replaceAll('هذه', 'هاذه');
    normalized = normalized.replaceAll('هذان', 'هاذان');
    normalized = normalized.replaceAll('ذلك', 'ذالك');
    normalized = normalized.replaceAll('ذلكم', 'ذالكم');
    normalized = normalized.replaceAll('كذلك', 'كذالك');
    normalized = normalized.replaceAll('اله', 'الاه');
    normalized = normalized.replaceAll('اللهم', 'اللاههم');
    normalized = normalized.replaceAll('السموات', 'السماوات');
    normalized = normalized.replaceAll('لكن', 'لاكن');
    normalized = normalized.replaceAll('اولئك', 'اولائك');
    
    // Fix Uthmani expanded Waw seats
    normalized = normalized.replaceAll('صلواه', 'صلاه');
    normalized = normalized.replaceAll('زكواه', 'زكاه');
    normalized = normalized.replaceAll('حيواه', 'حياه');
    normalized = normalized.replaceAll('مشكواه', 'مشكاه');
    normalized = normalized.replaceAll('غدواه', 'غداه');
    normalized = normalized.replaceAll('نجواه', 'نجاه');
    normalized = normalized.replaceAll('ربوا', 'ربا');

    // Fix Uthmani expanded Yaa seats at the end of words (موسيا -> موسي)
    // Dart regex \b does not work well with Arabic, using (?=\s|$) instead
    normalized = normalized.replaceAllMapped(RegExp(r'(\S+)يا(?=\s|$)'), (match) {
      return '${match[1]}ي';
    });

    normalized = normalized.replaceAll('داوود', 'داود');
    
    // Remove punctuation, zero-width spaces, and extra whitespace
    normalized = normalized.replaceAll(RegExp(r'[.,;؛؟!?\-\u200B\u200C\u200D\uFEFF]'), ' ');
    
    // Replace multiple spaces with a single space and trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // specific multi-word mapping after spaces are normalized
    normalized = normalized.replaceAll('يا ايها', 'ياايها'); 

    return normalized;
  }
}
