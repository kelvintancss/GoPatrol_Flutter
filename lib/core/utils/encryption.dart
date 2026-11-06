import 'dart:math';

class EncryptionUtils {
  static String encryptPassword(String password) {
    if (password.isEmpty) return '';

    final random = Random();
    String cCrypAsc = '';
    String cRandomNum;
    String cEncryptChr;

    // toUpperCase (same as C#)
    String lcString = password.toUpperCase();

    /// Step 1: generate first 6 random numbers
    for (int i = 0; i < 6; i++) {
      cRandomNum = random.nextInt(10).toString();
      int num = int.parse(cRandomNum);
      if (num > 6) {
        num = (num / 2).floor();
      }
      if (num == 0) {
        num = 1;
      }
      cCrypAsc += num.toString();
    }

    int nCharPos = 1;

    /// Step 2: encrypt each character
    while (lcString.isNotEmpty) {
      // ASCII value
      cEncryptChr = lcString.codeUnitAt(0).toString();

      // Note: In the original code, if ASCII > 95 it returns a Text widget
      // But here we're returning a String, so we'll handle it differently
      if (int.parse(cEncryptChr) > 95) {
        // You might want to throw an exception or handle this case
        throw Exception('Invalid character in password');
      }

      int repeatCount = int.parse(cCrypAsc.substring(nCharPos - 1, nCharPos));

      for (int i = 0; i < repeatCount; i++) {
        cRandomNum = random.nextInt(10).toString();
        if (cRandomNum == '9') {
          cRandomNum = '8';
        }
        cCrypAsc += cRandomNum;
      }

      cCrypAsc += cEncryptChr;
      lcString = lcString.substring(1);
      nCharPos++;
      if (nCharPos == 7) nCharPos = 1;
    }

    /// Step 3: each group of 3 digits +1
    String strFinal = '';
    String strCoach = '';

    while (cCrypAsc.length > 2) {
      strCoach = cCrypAsc.substring(0, 3);
      cCrypAsc = cCrypAsc.substring(3);

      int value = int.parse(strCoach) + 1;
      strFinal += value.toString().padLeft(3, '0');
    }

    // capture remainders
    strFinal += cCrypAsc;

    return strFinal;
  }
}
