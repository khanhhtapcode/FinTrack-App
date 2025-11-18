import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import '../models/receipt_data.dart';

/// Top-level isolate function for image preprocessing (runs off UI thread)
Uint8List _preprocessImageBytes(List<int> originalBytes) {
  try {
    final decoded = img.decodeImage(Uint8List.fromList(originalBytes));
    if (decoded == null) {
      // Return original if decode fails
      return Uint8List.fromList(originalBytes);
    }

    img.Image working = decoded;

    // Aggressive resize to 512px to prevent OOM
    if (working.width > 512 || working.height > 512) {
      if (working.width >= working.height) {
        working = img.copyResize(working, width: 512);
      } else {
        working = img.copyResize(working, height: 512);
      }
    }

    // Skip color adjustment to reduce processing time and memory
    // Compress JPEG 70% quality (balance size vs quality)
    final compressed = img.encodeJpg(working, quality: 70);
    return Uint8List.fromList(compressed);
  } catch (e) {
    // If any processing fails, return original bytes
    debugPrint('[Isolate] Image processing error: $e');
    return Uint8List.fromList(originalBytes);
  }
}

class GeminiOcrService {
  late final GenerativeModel _model;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const bool _enableVerboseLogs =
      true; // toggle detailed logs (used in parsing)

  GeminiOcrService() {
    final raw = dotenv.env['GEMINI_API_KEY'];
    final apiKey = raw?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not found in .env file. Please add your API key.',
      );
    }

    _model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
  }

  /// Scan receipt image and extract transaction data
  Future<ReceiptData> scanReceipt(File imageFile) async {
    final totalSw = Stopwatch()..start();
    try {
      debugPrint('[GeminiOCR] Starting scan...');

      final preprocessSw = Stopwatch()..start();
      final processedImage = await _preprocessImage(imageFile);
      preprocessSw.stop();
      final imgSizeMB = (processedImage.length / 1024 / 1024).toStringAsFixed(
        2,
      );
      debugPrint(
        '[GeminiOCR] Preprocess took ${preprocessSw.elapsedMilliseconds}ms, output: $imgSizeMB MB',
      );

      final prompt = _buildPrompt();

      final apiSw = Stopwatch()..start();
      final response = await _callGeminiWithRetry(processedImage, prompt);
      apiSw.stop();
      debugPrint('[GeminiOCR] API call took ${apiSw.elapsedMilliseconds}ms');

      final parseSw = Stopwatch()..start();
      final receiptData = _parseResponse(response);
      parseSw.stop();
      debugPrint('[GeminiOCR] Parse took ${parseSw.elapsedMilliseconds}ms');

      totalSw.stop();
      debugPrint(
        '[GeminiOCR] Total scanReceipt duration ${totalSw.elapsedMilliseconds}ms',
      );
      return receiptData;
    } catch (e, stack) {
      totalSw.stop();
      debugPrint(
        '[GeminiOCR][ERROR] Scan failed after ${totalSw.elapsedMilliseconds}ms',
      );
      debugPrint('[GeminiOCR][ERROR] Exception: $e');
      debugPrint('[GeminiOCR][ERROR] Stack: $stack');

      // Return default data instead of rethrowing to prevent app crash
      return ReceiptData(
        merchant: 'Error',
        amount: 0,
        date: DateTime.now(),
        category: 'Other',
        items: [],
        confidence: 0.0,
        notes: 'Scan failed: ${e.toString()}',
      );
    }
  }

  /// Preprocess image: resize, compress, enhance
  Future<Uint8List> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final sizeMB = (bytes.length / 1024 / 1024).toStringAsFixed(2);
      debugPrint('[GeminiOCR] Image size: ${bytes.length} bytes ($sizeMB MB)');

      // If image too large, skip isolate processing
      if (bytes.length > 10 * 1024 * 1024) {
        // >10MB
        debugPrint('[GeminiOCR] Image too large, returning original');
        return bytes;
      }

      // Offload with timeout to prevent hanging
      return await compute(_preprocessImageBytes, bytes).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[GeminiOCR] Preprocessing timeout, returning original');
          return bytes;
        },
      );
    } catch (e, stack) {
      debugPrint('[GeminiOCR] Preprocessing failed: $e');
      debugPrint('[GeminiOCR] Stack: $stack');
      // Fallback: return original bytes
      return await imageFile.readAsBytes();
    }
  }

  /// Build optimized prompt for Gemini
  String _buildPrompt() {
    return '''
Analyze this receipt/invoice image and extract transaction information.

Requirements:
1. Merchant name (tên cửa hàng/công ty) - Keep original Vietnamese if applicable
2. Total amount in VND (số tiền) - Extract ONLY the final total after all taxes/discounts
3. Date (format: DD/MM/YYYY) - If not found, use today's date
4. Category - Choose EXACTLY ONE from this list:
   - Food & Drink (Ăn uống, nhà hàng, cafe, food delivery)
   - Shopping (Mua sắm, siêu thị, quần áo, đồ dùng)
   - Transport (Đi lại, xăng xe, taxi, grab, vé xe)
   - Entertainment (Giải trí, phim ảnh, game, du lịch)
   - Bills (Hóa đơn, điện nước, internet, điện thoại)
   - Healthcare (Y tế, thuốc, bệnh viện)
   - Education (Giáo dục, sách vở, học phí)
   - Other (Khác)
5. Items purchased (optional, max 5 items, ngắn gọn)
6. Confidence score (0.0 to 1.0) - Your confidence in the extraction accuracy

Important rules:
- For amount: Remove all non-numeric characters except decimal point
- If multiple totals shown, take the FINAL total (after tax/discount)
- Date format must be DD/MM/YYYY
- Category must be exactly one of the listed options
- For Vietnamese receipts, preserve Vietnamese characters
- If information is unclear, use reasonable defaults and lower confidence score

Return ONLY valid JSON in this EXACT format (no markdown, no code blocks):
{
  "merchant": "Tên cửa hàng",
  "amount": 150000,
  "date": "18/11/2025",
  "category": "Food & Drink",
  "items": ["Cơm", "Nước ngọt"],
  "confidence": 0.95
}
''';
  }

  /// Call Gemini API with retry logic
  Future<String> _callGeminiWithRetry(
    Uint8List imageBytes,
    String prompt,
  ) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('Gemini API call attempt $attempt/$_maxRetries');

        final content = [
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
        ];

        final response = await _model.generateContent(content);

        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from Gemini API');
        }

        debugPrint('Gemini response: ${response.text}');
        return response.text!;
      } on GenerativeAIException catch (e) {
        lastException = e;
        debugPrint('Gemini API error (attempt $attempt): ${e.message}');

        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        }
      } catch (e) {
        lastException = Exception('Unexpected error: $e');
        debugPrint('Unexpected error (attempt $attempt): $e');

        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    throw lastException ??
        Exception('Failed to call Gemini API after $_maxRetries attempts');
  }

  /// Parse Gemini response to ReceiptData
  ReceiptData _parseResponse(String response) {
    try {
      // Clean response (remove markdown code blocks if present)
      String cleanedResponse = response.trim();

      // Remove markdown code blocks
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }

      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(
          0,
          cleanedResponse.length - 3,
        );
      }

      cleanedResponse = cleanedResponse.trim();

      // Parse JSON
      final decodeSw = Stopwatch()..start();
      final Map<String, dynamic> json = jsonDecode(cleanedResponse);
      decodeSw.stop();
      if (_enableVerboseLogs) {
        debugPrint(
          '[GeminiOCR] JSON decode took ${decodeSw.elapsedMilliseconds}ms',
        );
      }

      // Validate required fields
      if (!json.containsKey('merchant') ||
          !json.containsKey('amount') ||
          !json.containsKey('date') ||
          !json.containsKey('category')) {
        throw Exception('Missing required fields in response');
      }

      // Create ReceiptData from JSON
      final receiptData = ReceiptData.fromJson(json);

      // Validate data
      if (receiptData.amount <= 0) {
        throw Exception('Invalid amount: ${receiptData.amount}');
      }

      return receiptData;
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      debugPrint('Raw response: $response');

      // Return default data with low confidence
      return ReceiptData(
        merchant: 'Unknown',
        amount: 0,
        date: DateTime.now(),
        category: 'Other',
        items: [],
        confidence: 0.0,
        notes: 'Failed to parse receipt: $e',
      );
    }
  }

  /// Check if API key is configured
  static bool isConfigured() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      return apiKey != null &&
          apiKey.isNotEmpty &&
          apiKey != 'your_gemini_api_key_here';
    } catch (e) {
      return false;
    }
  }
}
