import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter_test/flutter_test.dart';

String _initials(String name) => TeamInfo(name: name, logoUrl: '').initials;

void main() {
  test('one word gives its first three letters', () {
    expect(_initials('Australia'), 'AUS');
    expect(_initials('Bangladesh'), 'BAN');
    expect(_initials('India'), 'IND');
    expect(_initials('Afghanistan'), 'AFG');
    expect(_initials('india'), 'IND');
  });

  test('several words give the first letter of each, up to three', () {
    expect(_initials('New Zealand'), 'NZ');
    expect(_initials('Sri Lanka'), 'SL');
    expect(_initials('West Indies'), 'WI');
    expect(_initials('South Africa'), 'SA');
    expect(_initials('Papua New Guinea'), 'PNG');
    expect(_initials('United Arab Emirates'), 'UAE');
    expect(_initials('Chennai Super Kings'), 'CSK');
    expect(_initials('Royal Challengers Bengaluru'), 'RCB');
    expect(_initials('One Two Three Four'), 'OTT');
  });

  test('joining words are left out', () {
    expect(_initials('United States of America'), 'USA');
    expect(_initials('Trinidad and Tobago'), 'TT');
    expect(_initials('Trinidad & Tobago'), 'TT');
    expect(_initials('The Oval Invincibles'), 'OI');
  });

  test('trailing qualifiers are left out', () {
    expect(_initials('India A'), 'IND');
    expect(_initials('New Zealand A'), 'NZ');
    expect(_initials('Afghanistan U19'), 'AFG');
    expect(_initials('Afghanistan U-19'), 'AFG');
    expect(_initials('Sri Lanka Under-19'), 'SL');
    expect(_initials('Namibia Women'), 'NAM');
    expect(_initials('Perth Scorchers Women'), 'PS');
    expect(_initials('Pakistan Shaheens XI'), 'PS');
    expect(_initials('England W'), 'ENG');
  });

  test('a name made only of a qualifier or joining word keeps it', () {
    expect(_initials('A'), 'A');
    expect(_initials('The'), 'THE');
  });

  test('two to four capitals are kept as they are', () {
    expect(_initials('USA'), 'USA');
    expect(_initials('UAE'), 'UAE');
    expect(_initials('MSW'), 'MSW');
    expect(_initials('PNGW'), 'PNGW');
    expect(_initials('USOAW'), 'USO');
  });

  test('punctuation and extra spaces are ignored', () {
    expect(_initials('  St. Lucia   Kings '), 'SLK');
    expect(_initials('(Hong Kong)'), 'HK');
  });

  test('names in other scripts use whole characters', () {
    // Vowel signs and marks stay with their letter: বাং is one character.
    expect(_initials('বাংলাদেশ'), 'বাংলাদে');
    expect(_initials('ভারত'), 'ভারত');
    expect(_initials('श्रीलंका'), 'श्रीलंका');
    expect(_initials('नेपाल टीम'), 'नेटी');
  });

  test('an empty name gives a question mark', () {
    expect(_initials(''), '?');
    expect(_initials('   '), '?');
    expect(_initials('...'), '?');
  });
}
