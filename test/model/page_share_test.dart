import 'package:codedbykay_text_tv/model/page_share.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:flutter_test/flutter_test.dart';

const TextTvPage _page = TextTvPage(
  number: 377,
  parts: <List<String>>[
    <String>['', '377 SVT Text', 'Rubrik', '  indenterad rad', '', ''],
    <String>['377 del två', 'Mer'],
  ],
);

void main() {
  shareLinkTests();

  group('pageText', () {
    test('is the rows, without the empty ones at the top and bottom', () {
      expect(pageText(_page, 0), '377 SVT Text\nRubrik\n  indenterad rad');
    });

    test('keeps the spacing inside, so columns still line up', () {
      expect(pageText(_page, 0), contains('  indenterad rad'));
    });

    test('reads the part asked for, and the nearest one if there is none', () {
      expect(pageText(_page, 1), '377 del två\nMer');
      expect(pageText(_page, 9), '377 del två\nMer');
      expect(pageText(_page, -1), startsWith('377 SVT Text'));
    });

    test('a page with nothing on it is empty text', () {
      const TextTvPage empty = TextTvPage(number: 100, parts: <List<String>>[]);

      expect(pageText(empty, 0), '');
    });
  });

  group('pageLink', () {
    test('is the page on texttv.nu', () {
      expect(pageLink(377), 'https://texttv.nu/377');
    });
  });

  group('shareMessage', () {
    test('is the page text and, after a blank line, its link', () {
      expect(
        shareMessage(_page, 1),
        '377 del två\nMer\n\nhttps://texttv.nu/377',
      );
    });
  });
}

void shareLinkTests() {
  group('shareLinkFor', () {
    test('is the link that names this version, when the site gave one', () {
      const TextTvPage page = TextTvPage(
        number: 377,
        parts: <List<String>>[
          <String>['x'],
        ],
        permalink: 'https://texttv.nu/377/malservice-37397964',
      );

      expect(shareLinkFor(page), 'https://texttv.nu/377/malservice-37397964');
      expect(
        shareMessage(page, 0),
        'x\n\nhttps://texttv.nu/377/malservice-37397964',
      );
    });

    test('else the page\'s own address', () {
      const TextTvPage page = TextTvPage(
        number: 377,
        parts: <List<String>>[
          <String>['x'],
        ],
      );

      expect(shareLinkFor(page), 'https://texttv.nu/377');
    });
  });
}
