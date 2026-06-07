import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/data/surahs.json');
  final jsonStr = file.readAsStringSync();
  final list = jsonDecode(jsonStr) as List<dynamic>;
  stdout.writeln(list.length);
}
