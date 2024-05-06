extension String2 on String {
  String toTitleCase() {
    String result = '';
    for (int i = 0; i < length; i++) {
      final c = this[i];
      if (i > 1 &&
          isCodeUnitCapitalLetter(codeUnitAt(i)) &&
          isCodeUnitSmallLetter(codeUnitAt(i - 1))) {
        result += ' ';
      }
      result += c;
    }
    return result;
  }

  static bool isCodeUnitSmallLetter(int i) => i >= 97 && i <= 122;

  static bool isCodeUnitCapitalLetter(int i) => i >= 65 && i <= 90;
}
