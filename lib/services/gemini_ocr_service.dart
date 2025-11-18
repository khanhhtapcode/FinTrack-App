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
  final decoded = img.decodeImage(Uint8List.fromList(originalBytes));
  if (decoded == null) {
    throw Exception('Failed to decode image');
  }

  img.Image working = decoded;

  // Resize keeping aspect ratio, max dimension 800 (faster preprocess)
  if (working.width > 800 || working.height > 800) {
    if (working.width >= working.height) {
      working = img.copyResize(working, width: 800);
    } else {
      working = img.copyResize(working, height: 800);
    }
  }

  // Enhance contrast & brightness for OCR clarity
  working = img.adjustColor(working, contrast: 1.2, brightness: 1.05);

  // Compress JPEG 85% quality
  final compressed = img.encodeJpg(working, quality: 85);
  return Uint8List.fromList(compressed);
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
      final preprocessSw = Stopwatch()..start();
      final processedImage = await _preprocessImage(imageFile);
      preprocessSw.stop();
      debugPrint(
        '[GeminiOCR] Preprocess (isolate) took ${preprocessSw.elapsedMilliseconds}ms',
      );
      if (preprocessSw.elapsedMilliseconds > 400) {
        debugPrint(
          '[GeminiOCR][Warn] Preprocess slow (>400ms). Consider stronger downscale.',
        );
      }

      final prompt = _buildPrompt();

      final apiSw = Stopwatch()..start();
      final response = await _callGeminiWithRetry(processedImage, prompt);
      apiSw.stop();
      debugPrint('[GeminiOCR] API call took ${apiSw.elapsedMilliseconds}ms');
      if (apiSw.elapsedMilliseconds > 4500) {
        debugPrint(
          '[GeminiOCR][Warn] API latency high (>4500ms). Possible network slowdown.',
        );
      }

      final parseSw = Stopwatch()..start();
      final receiptData = _parseResponse(response);
      parseSw.stop();
      debugPrint('[GeminiOCR] Parse took ${parseSw.elapsedMilliseconds}ms');
      if (parseSw.elapsedMilliseconds > 300) {
        debugPrint('[GeminiOCR][Warn] Parsing slow (>300ms). Large response?');
      }

      totalSw.stop();
      debugPrint(
        '[GeminiOCR] Total scanReceipt duration ${totalSw.elapsedMilliseconds}ms',
      );
      if (totalSw.elapsedMilliseconds > 5500) {
        debugPrint(
          '[GeminiOCR][Warn] End-to-end OCR slow (>5500ms). Investigate network + CPU load.',
        );
      }
      return receiptData;
    } catch (e) {
      totalSw.stop();
      debugPrint(
        '[GeminiOCR] Error scanning receipt after ${totalSw.elapsedMilliseconds}ms: $e',
      );
      rethrow;
    }
  }

  /// Preprocess image: resize, compress, enhance
  Future<Uint8List> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Offload heavy work to isolate to reduce UI jank
      return await compute(_preprocessImageBytes, bytes);
    } catch (e) {
      debugPrint(
        '[GeminiOCR] Isolate preprocessing failed, fallback to original bytes: $e',
      );
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
