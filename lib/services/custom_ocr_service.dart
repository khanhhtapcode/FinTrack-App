// Custom OCR Service - ONNX Runtime Implementation
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';

class CustomOCRService {
  // Singleton pattern
  static final CustomOCRService _instance = CustomOCRService._internal();
  factory CustomOCRService() => _instance;
  CustomOCRService._internal();

  OrtSession? _session;
  bool _isInitialized = false;

  // Vietnamese charset (copy từ training notebook Cell 9)
  static const List<String> charset = [
    '<BLANK>',
    ' ',
    '!',
    '"',
    '#',
    '\$',
    '%',
    '&',
    '\'',
    '(',
    ')',
    '*',
    '+',
    ',',
    '-',
    '.',
    '/',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    ':',
    ';',
    '<',
    '=',
    '>',
    '?',
    '@',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '[',
    ']',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '{',
    '|',
    '}',
    'à',
    'á',
    'â',
    'ã',
    'è',
    'é',
    'ê',
    'ì',
    'í',
    'ò',
    'ó',
    'ô',
    'õ',
    'ù',
    'ú',
    'ý',
    'ă',
    'đ',
    'ĩ',
    'ũ',
    'ơ',
    'ư',
    'ạ',
    'ả',
    'ấ',
    'ầ',
    'ẩ',
    'ẫ',
    'ậ',
    'ắ',
    'ằ',
    'ẳ',
    'ẵ',
    'ặ',
    'ẹ',
    'ẻ',
    'ẽ',
    'ế',
    'ề',
    'ể',
    'ễ',
    'ệ',
    'ỉ',
    'ị',
    'ọ',
    'ỏ',
    'ố',
    'ồ',
    'ổ',
    'ỗ',
    'ộ',
    'ớ',
    'ờ',
    'ở',
    'ỡ',
    'ợ',
    'ụ',
    'ủ',
    'ứ',
    'ừ',
    'ử',
    'ữ',
    'ự',
    'ỳ',
    'ỵ',
    'ỷ',
    'ỹ',
    'Ă',
    'Đ',
    'Ĩ',
    'Ũ',
    'Ơ',
    'Ư',
    'Ạ',
    'Ả',
    'Ấ',
    'Ầ',
    'Ẩ',
    'Ẫ',
    'Ậ',
    'Ắ',
    'Ằ',
    'Ẳ',
    'Ẵ',
    'Ặ',
    'Ẹ',
    'Ẻ',
    'Ẽ',
    'Ế',
    'Ề',
    'Ể',
    'Ễ',
    'Ệ',
    'Ỉ',
    'Ị',
    'Ọ',
    'Ỏ',
    'Ố',
    'Ồ',
    'Ổ',
    'Ỗ',
    'Ộ',
    'Ớ',
    'Ờ',
    'Ở',
    'Ỡ',
    'Ợ',
    'Ụ',
    'Ủ',
    'Ứ',
    'Ừ',
    'Ử',
    'Ữ',
    'Ự',
    'Ỳ',
    'Ỵ',
    'Ỷ',
    'Ỹ',
  ];

  Future<void> initialize() async {
    try {
      // Initialize ONNX Runtime environment
      OrtEnv.instance.init();

      // Load model from assets
      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/models/vietnamese_ocr_model.onnx';
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);

      _isInitialized = true;
      print('✅ Custom OCR model loaded');
    } catch (e) {
      print('❌ Error loading OCR model: $e');
      _isInitialized = false;
    }
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }

  Future<OCRResult?> scanFromCamera() async {
    // TODO: Implement after training
    return null;
  }

  Future<OCRResult?> pickFromGallery() async {
    // TODO: Implement after training
    return null;
  }

  Future<OCRResult?> processImage(String imagePath) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized || _session == null) return null;

    try {
      // 1. Load and decode image
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // 2. Preprocess image
      final input = _preprocessImage(image);

      // 3. Create ONNX input tensor
      final inputOrt = OrtValueTensor.createTensorWithDataList(input, [
        1,
        3,
        64,
        (input.length / (3 * 64)).round(),
      ]);

      // 4. Run inference
      final runOptions = OrtRunOptions();
      final inputs = {'input': inputOrt};
      final outputs = _session!.run(runOptions, inputs);

      // 5. Get output tensor
      final outputTensor = outputs[0]?.value as List;

      // 6. Decode CTC
      final text = _decodeCTC(outputTensor);

      // 7. Extract info
      final amount = _extractAmount(text);
      final date = _extractDate(text);
      final categories = _suggestCategories(text);

      // Cleanup
      inputOrt.release();
      outputs[0]?.release();

      return OCRResult(
        fullText: text,
        amount: amount,
        date: date,
        suggestedCategories: categories,
      );
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  Float32List _preprocessImage(img.Image image) {
    // Resize to height=64, keep aspect ratio
    final resized = img.copyResize(image, height: 64);
    final width = resized.width;

    // Convert to Float32List [1, 3, 64, width]
    final inputData = Float32List(1 * 3 * 64 * width);
    int idx = 0;

    // Format: [batch, channels, height, width]
    for (int c = 0; c < 3; c++) {
      for (int h = 0; h < 64; h++) {
        for (int w = 0; w < width; w++) {
          final pixel = resized.getPixel(w, h);
          late double value;
          if (c == 0) {
            value = pixel.r / 255.0;
          } else if (c == 1) {
            value = pixel.g / 255.0;
          } else {
            value = pixel.b / 255.0;
          }
          inputData[idx++] = value;
        }
      }
    }

    return inputData;
  }

  String _decodeCTC(List<dynamic> output) {
    // Output shape: [sequence_length, batch_size=1, num_chars]
    final decoded = <String>[];
    int? prevIdx;

    for (var timestep in output) {
      if (timestep is! List || timestep.isEmpty) continue;

      final probs = timestep[0] as List; // Get batch 0

      // Find max probability index
      double maxProb = double.negativeInfinity;
      int maxIdx = 0;
      for (int i = 0; i < probs.length; i++) {
        final prob = (probs[i] as num).toDouble();
        if (prob > maxProb) {
          maxProb = prob;
          maxIdx = i;
        }
      }

      // CTC decoding: skip blank (0) and consecutive duplicates
      if (maxIdx != 0 && maxIdx != prevIdx && maxIdx < charset.length) {
        decoded.add(charset[maxIdx]);
      }
      prevIdx = maxIdx;
    }

    return decoded.join('');
  }

  double? _extractAmount(String text) {
    // Regex patterns for Vietnamese currency
    final patterns = [
      r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*(?:VND|đ|dong)',
      r'(?:total|tổng|cộng)[:\s]*(\d{1,3}(?:[.,]\d{3})*)',
    ];

    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(RegExp(r'[.,]'), '');
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  DateTime? _extractDate(String text) {
    // Regex patterns for dates
    final patterns = [
      r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})',
      r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})',
    ];

    for (final pattern in patterns) {
      final match = RegExp(pattern).firstMatch(text);
      if (match != null) {
        try {
          return DateTime(
            int.parse(match.group(3)!),
            int.parse(match.group(2)!),
            int.parse(match.group(1)!),
          );
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  List<String> _suggestCategories(String text) {
    // Keyword-based category suggestions
    final textLower = text.toLowerCase();
    final categories = <String>[];

    if (textLower.contains('cà phê') || textLower.contains('cafe')) {
      categories.add('Ăn uống');
    }
    if (textLower.contains('xăng') || textLower.contains('petrol')) {
      categories.add('Đi lại');
    }
    // TODO: Add more patterns

    return categories;
  }
}

class OCRResult {
  final String fullText;
  final double? amount;
  final DateTime? date;
  final List<String> suggestedCategories;

  OCRResult({
    required this.fullText,
    this.amount,
    this.date,
    required this.suggestedCategories,
  });
}

// INSTRUCTIONS:
// 1. Train model using vietnamese_receipt_ocr_training.ipynb
// 2. Copy vietnamese_ocr_model.tflite to assets/models/
// 3. Update pubspec.yaml with tflite_flutter dependency
// 4. Uncomment and complete this implementation
// 5. Replace OCRService references in AddTransactionScreen
