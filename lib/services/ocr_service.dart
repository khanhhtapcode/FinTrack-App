import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Singleton pattern
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  /// Scan receipt from camera
  Future<OCRResult?> scanFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processImage(image);
    } catch (e) {
      print('Error scanning from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<OCRResult?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processImage(image);
    } catch (e) {
      print('Error picking from gallery: $e');
      return null;
    }
  }

  /// Process image with ML Kit OCR
  Future<OCRResult> _processImage(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    // Extract text
    String fullText = recognizedText.text;

    // Parse amount and other info
    double? amount = _extractAmount(fullText);
    String? date = _extractDate(fullText);
    List<String> categories = _suggestCategories(fullText);

    return OCRResult(
      fullText: fullText,
      amount: amount,
      date: date,
      suggestedCategories: categories,
      imagePath: image.path,
    );
  }

  /// Extract amount from text (Vietnamese format)
  double? _extractAmount(String text) {
    // Common patterns:
    // "Tổng cộng: 150,000"
    // "Thành tiền: 150.000"
    // "Total: 150000"
    // "150,000 VND"

    final patterns = [
      RegExp(
        r'(?:tổng|total|thành tiền|t[iî]ền|cộng)[:\s]*([0-9.,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9]{3}[.,][0-9]{3}(?:[.,][0-9]{3})*)\s*(?:đ|vnd|₫)?',
        caseSensitive: false,
      ),
      RegExp(r'([0-9]+[.,][0-9]{3})\s*(?:đ|vnd|₫)?', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        if (match.groupCount > 0) {
          String? numberStr = match.group(1);
          if (numberStr != null) {
            // Remove dots and commas, parse as double
            numberStr = numberStr.replaceAll(RegExp(r'[.,]'), '');
            double? amount = double.tryParse(numberStr);
            if (amount != null && amount > 0 && amount < 100000000) {
              return amount;
            }
          }
        }
      }
    }

    return null;
  }

  /// Extract date from text
  String? _extractDate(String text) {
    // Patterns: "16/11/2025", "16-11-2025", "16.11.2025"
    final datePattern = RegExp(r'(\d{1,2})[/-.](\d{1,2})[/-.](\d{2,4})');
    final match = datePattern.firstMatch(text);

    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Suggest categories based on keywords in text
  List<String> _suggestCategories(String text) {
    final lowerText = text.toLowerCase();
    List<String> categories = [];

    final categoryKeywords = {
      'Ăn uống': [
        'cà phê',
        'coffee',
        'cafe',
        'phở',
        'cơm',
        'bún',
        'bánh',
        'trà',
        'tea',
        'food',
        'restaurant',
        'nhà hàng',
        'quán',
      ],
      'Xăng xe': ['xăng', 'dầu', 'petrol', 'gas', 'fuel'],
      'Siêu thị': [
        'siêu thị',
        'supermarket',
        'vinmart',
        'coopmart',
        'lotte',
        'bigc',
      ],
      'Điện nước': ['điện', 'nước', 'electric', 'water', 'evn'],
      'Mua sắm': [
        'mua',
        'shopping',
        'thời trang',
        'fashion',
        'giày',
        'quần áo',
      ],
      'Y tế': [
        'bệnh viện',
        'hospital',
        'thuốc',
        'medicine',
        'khám',
        'phòng khám',
      ],
      'Giải trí': ['phim', 'movie', 'cinema', 'game', 'vui chơi'],
    };

    for (var entry in categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          if (!categories.contains(entry.key)) {
            categories.add(entry.key);
          }
          break;
        }
      }
    }

    return categories;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}

class OCRResult {
  final String fullText;
  final double? amount;
  final String? date;
  final List<String> suggestedCategories;
  final String imagePath;

  OCRResult({
    required this.fullText,
    this.amount,
    this.date,
    this.suggestedCategories = const [],
    required this.imagePath,
  });

  @override
  String toString() {
    return 'OCRResult(amount: $amount, date: $date, categories: $suggestedCategories)';
  }
}
