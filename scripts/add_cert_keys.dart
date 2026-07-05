import 'dart:convert';
import 'dart:io';

void main() {
  final arFile = File('lib/core/l10n/app_ar.arb');
  final enFile = File('lib/core/l10n/app_en.arb');

  final arMap = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;
  final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

  // Add Arabic keys
  arMap['certificateCelebrationMultiple'] = 'لقد حصلت على {count} شهادات جديدة';
  arMap['@certificateCelebrationMultiple'] = {
    'placeholders': {
      'count': {'type': 'int'},
    },
  };
  arMap['certificateCelebrationSingle'] = 'لقد حصلت على {title}';
  arMap['@certificateCelebrationSingle'] = {
    'placeholders': {
      'title': {'type': 'String'},
    },
  };

  // Add English keys
  enMap['certificateCelebrationMultiple'] =
      'You earned {count} new certificates!';
  enMap['@certificateCelebrationMultiple'] = {
    'placeholders': {
      'count': {'type': 'int'},
    },
  };
  enMap['certificateCelebrationSingle'] =
      'You earned a new certificate!'; // I'll just use title in english too if possible, but the original was "You earned a new certificate!". I'll change the dart code to handle it. Actually let's just make it 'You earned {title}'.
  enMap['certificateCelebrationSingle'] = 'You earned {title}';
  enMap['@certificateCelebrationSingle'] = {
    'placeholders': {
      'title': {'type': 'String'},
    },
  };

  const encoder = JsonEncoder.withIndent('  ');
  arFile.writeAsStringSync(encoder.convert(arMap));
  enFile.writeAsStringSync(encoder.convert(enMap));
  print('Added certificate celebration keys to ARB files.');
}
