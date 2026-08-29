import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtils {
  // Hashes input text (password or PIN) using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verifies if input password matches the stored hash
  static bool verifyPassword(String password, String storedHash) {
    return hashPassword(password) == storedHash;
  }
}
