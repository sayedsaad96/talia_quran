import 'dart:convert';
import 'dart:io';

void main() async {
  print('Fetching authentic Quran data...');
  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'));
    final response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();
    
    final jsonResponse = jsonDecode(stringData);
    final surahs = jsonResponse['data']['surahs'];
    
    // We will build a new JSON mapping exactly like the old one, but adding "page" and "juz" to each verse.
    final Map<String, dynamic> newData = {};
    
    for (var surah in surahs) {
      final surahId = surah['number'].toString();
      final ayahs = surah['ayahs'];
      
      final verseList = <Map<String, dynamic>>[];
      for (var ayah in ayahs) {
        verseList.add({
          'chapter': surah['number'],
          'verse': ayah['numberInSurah'],
          'text': ayah['text'],
          'page': ayah['page'],
          'juz': ayah['juz'],
          'global': ayah['number'] // global ayah number
        });
      }
      newData[surahId] = verseList;
    }
    
    final file = File('assets/data/quran.json');
    await file.writeAsString(jsonEncode(newData));
    print('Successfully saved authentic quran.json with page numbers!');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    httpClient.close();
  }
}
