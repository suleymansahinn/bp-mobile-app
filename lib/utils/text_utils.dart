class TextUtils {
  static String normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll("ı", "i")
        .replaceAll("İ", "i")
        .replaceAll("ğ", "g")
        .replaceAll("Ğ", "g")
        .replaceAll("ş", "s")
        .replaceAll("Ş", "s")
        .replaceAll("ö", "o")
        .replaceAll("Ö", "o")
        .replaceAll("ç", "c")
        .replaceAll("Ç", "c")
        .replaceAll("ü", "u")
        .replaceAll("Ü", "u");
  }
}