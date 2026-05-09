import 'dart:io';

({int width, int height})? getPngDimensions(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    if (bytes.length < 24) return null;
    if (bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4E ||
        bytes[3] != 0x47) {
      return null;
    }
    final w = bytes[16] << 24 | bytes[17] << 16 | bytes[18] << 8 | bytes[19];
    final h = bytes[20] << 24 | bytes[21] << 16 | bytes[22] << 8 | bytes[23];
    return (width: w, height: h);
  } catch (_) {
    return null;
  }
}

bool validatePngHeader(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    if (bytes.length < 8) return false;
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  } catch (_) {
    return false;
  }
}
