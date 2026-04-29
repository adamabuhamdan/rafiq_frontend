class NumberUtil {
  static String toEnglishNumbers(String input) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String output = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      output = output.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return output;
  }
}
