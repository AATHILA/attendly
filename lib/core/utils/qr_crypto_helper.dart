import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';

class QrValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const QrValidationResult({
    required this.isValid,
    this.errorMessage,
    this.data,
  });

  factory QrValidationResult.valid(Map<String, dynamic> data) =>
      QrValidationResult(isValid: true, data: data);

  factory QrValidationResult.invalid(String message) =>
      QrValidationResult(isValid: false, errorMessage: message);
}

class QrCryptoHelper {
  /// Generate an HMAC-SHA256 signature for a given raw payload string
  static String generateSignature(String rawData, {String? secret}) {
    final key = utf8.encode(secret ?? AppConstants.qrSecretKey);
    final bytes = utf8.encode(rawData);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Create a signed JSON string for the QR session
  static String createSignedQrPayload({
    required String sessionId,
    required String type, // 'CHECK_IN' or 'CHECK_OUT'
    required DateTime validFrom,
    required DateTime validUntil,
  }) {
    // Construct base payload
    final basePayload = {
      'sessionId': sessionId,
      'type': type,
      'validFrom': validFrom.millisecondsSinceEpoch,
      'validUntil': validUntil.millisecondsSinceEpoch,
    };

    // Serialize base payload to calculate HMAC
    final rawJsonString = jsonEncode(basePayload);
    final signature = generateSignature(rawJsonString);

    // Final payload with signature attached
    final fullPayload = {
      ...basePayload,
      'signature': signature,
    };

    return jsonEncode(fullPayload);
  }

  /// Validate a scanned QR code string
  static QrValidationResult validateQrPayload(String rawQrString) {
    try {
      final decoded = jsonDecode(rawQrString);
      if (decoded is! Map<String, dynamic>) {
        return QrValidationResult.invalid('Invalid QR code format.');
      }

      // Check required fields
      if (!decoded.containsKey('sessionId') ||
          !decoded.containsKey('type') ||
          !decoded.containsKey('validFrom') ||
          !decoded.containsKey('validUntil') ||
          !decoded.containsKey('signature')) {
        return QrValidationResult.invalid('Malformed QR code: Missing security keys.');
      }

      final String receivedSignature = decoded['signature'];
      final int validUntilMs = decoded['validUntil'];

      // Reconstruct base payload to verify signature
      final basePayload = {
        'sessionId': decoded['sessionId'],
        'type': decoded['type'],
        'validFrom': decoded['validFrom'],
        'validUntil': decoded['validUntil'],
      };

      final expectedSignature = generateSignature(jsonEncode(basePayload));

      // 1. Signature / Anti-tamper Check
      if (receivedSignature != expectedSignature) {
        return QrValidationResult.invalid('Security Alert: QR signature is invalid or tampered!');
      }

      // 2. Expiration Check
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs > validUntilMs) {
        return QrValidationResult.invalid('QR Code has expired! Please scan the active QR code.');
      }

      return QrValidationResult.valid(decoded);
    } catch (e) {
      return QrValidationResult.invalid('Failed to parse QR code: Not a valid Attendly QR code.');
    }
  }
}