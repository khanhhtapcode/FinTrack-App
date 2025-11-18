import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/receipt_data.dart';
import 'gemini_ocr_service.dart';
import 'custom_ocr_service.dart';

/// Unified OCR service that can use either Gemini or Custom OCR
class OcrService {
  final GeminiOcrService? _geminiService;
  final CustomOCRService _customService;

  bool _useGemini = true; // Default to Gemini if configured

  OcrService()
    : _geminiService = GeminiOcrService.isConfigured()
          ? GeminiOcrService()
          : null,
      _customService = CustomOCRService() {
    if (_geminiService == null) {
      debugPrint('⚠️ Gemini API not configured, will use custom OCR');
      _useGemini = false;
    }
  }

  /// Initialize OCR services
  Future<void> initialize() async {
    await _customService.initialize();
    debugPrint('✅ OCR Service initialized (Gemini: ${_geminiService != null})');
  }

  /// Check if Gemini OCR is available
  bool get isGeminiAvailable => _geminiService != null;

  /// Get current OCR mode
  bool get isUsingGemini => _useGemini && _geminiService != null;

  /// Switch OCR mode
  void setUseGemini(bool useGemini) {
    if (useGemini && _geminiService == null) {
      debugPrint('⚠️ Cannot use Gemini - not configured');
      return;
    }
    _useGemini = useGemini;
    debugPrint('Switched to ${useGemini ? "Gemini" : "Custom"} OCR');
  }

  /// Scan receipt using selected OCR service
  Future<ReceiptData?> scanReceipt(File imageFile) async {
    try {
      if (_useGemini && _geminiService != null) {
        debugPrint('🤖 Using Gemini OCR...');
        return await _scanWithGemini(imageFile);
      } else {
        debugPrint('🔧 Using Custom OCR...');
        return await _scanWithCustom(imageFile);
      }
    } catch (e) {
      debugPrint('❌ OCR Error: $e');

      // Fallback to custom OCR if Gemini fails
      if (_useGemini && _geminiService != null) {
        debugPrint('⚠️ Gemini failed, falling back to Custom OCR...');
        try {
          return await _scanWithCustom(imageFile);
        } catch (e2) {
          debugPrint('❌ Custom OCR also failed: $e2');
        }
      }

      return null;
    }
  }

  /// Scan with Gemini OCR
  Future<ReceiptData> _scanWithGemini(File imageFile) async {
    return await _geminiService!.scanReceipt(imageFile);
  }

  /// Scan with Custom OCR and convert to ReceiptData
  Future<ReceiptData?> _scanWithCustom(File imageFile) async {
    final result = await _customService.processImage(imageFile.path);

    if (result == null) {
      return null;
    }

    // Convert OCRResult to ReceiptData
    return ReceiptData(
      merchant: 'Unknown', // Custom OCR doesn't extract merchant
      amount: result.amount ?? 0.0,
      date: result.date ?? DateTime.now(),
      category: result.suggestedCategories.isNotEmpty
          ? _mapCustomCategoryToStandard(result.suggestedCategories.first)
          : 'Other',
      items: [], // Custom OCR doesn't extract items
      confidence: _estimateConfidence(result),
      notes: result.fullText.isNotEmpty ? result.fullText : null,
    );
  }

  double _estimateConfidence(OCRResult result) {
    double score = 0.2; // baseline when text is returned
    if (result.fullText.trim().isNotEmpty) {
      score += 0.2;
    }
    if (result.amount != null && result.amount! > 0) {
      score += 0.2;
    }
    if (result.date != null) {
      score += 0.2;
    }
    if (result.suggestedCategories.isNotEmpty) {
      score += 0.2;
    }
    return score.clamp(0.0, 1.0).toDouble();
  }

  /// Map custom OCR category to standard category
  String _mapCustomCategoryToStandard(String customCategory) {
    final mapping = {
      'Ăn uống': 'Food & Drink',
      'Xăng xe': 'Transport',
      'Shopping': 'Shopping',
      'Giải trí': 'Entertainment',
      'Y tế': 'Healthcare',
      'Giáo dục': 'Education',
      'Hóa đơn': 'Bills',
      'Điện nước': 'Bills',
      'Nhà cửa': 'Bills',
      'Quần áo': 'Shopping',
      'Làm đẹp': 'Shopping',
      'Thể thao': 'Entertainment',
      'Du lịch': 'Entertainment',
      'Điện thoại': 'Bills',
      'Internet': 'Bills',
    };

    return mapping[customCategory] ?? 'Other';
  }

  /// Dispose resources
  void dispose() {
    // Clean up if needed
  }
}
