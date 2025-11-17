# 🧾 Vietnamese Receipt OCR Training Project

## 📋 Tổng Quan Dự Án

Dự án training mô hình OCR nhận dạng văn bản tiếng Việt trên hóa đơn, sử dụng dataset **MC-OCR 2021** từ Kaggle.

**Mục tiêu:** Thay thế Google ML Kit bằng custom model có khả năng:
- Nhận dạng chính xác văn bản tiếng Việt
- Trích xuất số tiền (amount)
- Trích xuất ngày tháng (date)
- Tích hợp vào Flutter app (TFLite)

---

## 📂 Cấu Trúc Files

```
expense_tracker_app/
│
├── vietnamese_receipt_ocr_training.ipynb    # Jupyter Notebook chính
├── OCR_TRAINING_GUIDE.md                    # Hướng dẫn chi tiết + full code
├── OCR_TROUBLESHOOTING.md                   # Fix lỗi OCR hiện tại
├── README_OCR_PROJECT.md                    # File này
│
└── lib/services/ocr_service.dart            # OCR service hiện tại (ML Kit)
```

---

## 🚀 Quick Start Guide

### Bước 1: Chuẩn Bị

1. **Tạo tài khoản Kaggle:**
   - Truy cập [kaggle.com](https://www.kaggle.com)
   - Đăng ký/đăng nhập
   - Vào **Account** → **Create New API Token**
   - Download file `kaggle.json`

2. **Mở Google Colab:**
   - Truy cập [colab.research.google.com](https://colab.research.google.com)
   - **File** → **Upload notebook**
   - Chọn `vietnamese_receipt_ocr_training.ipynb`
   - **Runtime** → **Change runtime type** → **GPU** (T4 hoặc V100)

### Bước 2: Chạy Notebook

#### Phần 1-4: Setup & Phân Tích Dataset

```python
# Chạy lần lượt cells 1-14
Cell 1:  ✅ Kiểm tra GPU, cài thư viện
Cell 2:  ✅ Import libraries
Cell 3:  ⚠️ Upload kaggle.json (chọn file từ máy)
Cell 4:  ✅ Download dataset (~1.5GB, mất 3-5 phút)
Cell 5:  ✅ Khám phá cấu trúc dataset
Cell 6:  ✅ Phân tích annotations
Cell 7:  ✅ Đọc sample annotation
Cell 8:  ✅ Visualize 3 ảnh mẫu
Cell 9:  ✅ Xây dựng vocabulary (Vietnamese charset)
Cell 10: ✅ Preprocessing functions
Cell 11: ✅ Dataset class
Cell 12: ✅ CRNN model
Cell 13: ✅ Collate function
Cell 14: ✅ Training config
```

**🎯 Output:** Hiểu rõ cấu trúc dataset, có vocabulary, model CRNN sẵn sàng

#### Phần 5: Training (Copy từ OCR_TRAINING_GUIDE.md)

**Cell 15-17:**

1. Mở file **`OCR_TRAINING_GUIDE.md`**
2. Copy toàn bộ section **"1️⃣ COMPLETE TRAINING LOOP CODE"**
3. Paste vào **Cell 15**
4. Copy section **"2️⃣ CREATE DATALOADERS"**
5. Paste vào **Cell 16**
6. Copy section **"3️⃣ START TRAINING"**
7. Paste vào **Cell 17**
8. Chạy **Cell 15 → Cell 16 → Cell 17**

**⏱️ Training Time:** 2-4 hours (50 epochs)

**📊 Monitor:**
- Train Loss giảm dần
- Val CER (Character Error Rate) giảm < 15%
- Sample predictions cải thiện theo epochs

#### Phần 6: Export Models

**Cell 18-22:**

1. Copy sections **4️⃣-7️⃣** từ `OCR_TRAINING_GUIDE.md`
2. Paste vào cells tương ứng
3. Chạy để:
   - Test inference trên ảnh mẫu
   - Export ONNX model
   - Convert TFLite model
   - Download models về máy

**📦 Kết quả:**
```
trained_models.zip
├── best_model.pth                      # PyTorch checkpoint
├── vietnamese_ocr_model.onnx           # ONNX format
├── vietnamese_ocr_model.tflite         # TFLite (cho Flutter)
├── training_curves.png                 # Loss/CER curves
└── checkpoint_epoch_*.pth              # Intermediate checkpoints
```

### Bước 3: Tích Hợp Vào Flutter

#### 3.1 Copy Model File

```bash
# Extract trained_models.zip
unzip trained_models.zip

# Copy TFLite model vào Flutter project
cp checkpoints/vietnamese_ocr_model.tflite \
   expense_tracker_app/assets/models/
```

#### 3.2 Update pubspec.yaml

```yaml
dependencies:
  tflite_flutter: ^0.10.4

flutter:
  assets:
    - assets/models/vietnamese_ocr_model.tflite
```

#### 3.3 Thay Thế OCR Service

**File mới:** `lib/services/custom_ocr_service.dart`

```dart
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class CustomOCRService {
  late Interpreter _interpreter;
  bool _isInitialized = false;
  
  // Vietnamese charset (same as training)
  static const charset = [...];  // Copy từ training notebook
  
  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/vietnamese_ocr_model.tflite'
      );
      _isInitialized = true;
      print('✅ Custom OCR model loaded');
    } catch (e) {
      print('❌ Error loading model: $e');
    }
  }
  
  Future<Map<String, dynamic>> processImage(String imagePath) async {
    if (!_isInitialized) await initialize();
    
    // 1. Load image
    final imageBytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    // 2. Preprocess
    final input = preprocessImage(image!);
    
    // 3. Run inference
    var output = List.filled(outputLength, 0.0).reshape([...]);
    _interpreter.run(input, output);
    
    // 4. Decode CTC output
    final text = decodeCTC(output);
    
    // 5. Extract amount & date (regex như cũ)
    final amount = _extractAmount(text);
    final date = _extractDate(text);
    
    return {
      'text': text,
      'amount': amount,
      'date': date,
    };
  }
  
  Float32List preprocessImage(img.Image image) {
    // Resize to height=64, keep aspect ratio
    final resized = img.copyResize(
      image, 
      height: 64,
      interpolation: img.Interpolation.linear
    );
    
    // Convert to grayscale
    final grayscale = img.grayscale(resized);
    
    // Normalize [0, 1]
    final normalized = Float32List(3 * 64 * resized.width);
    for (int y = 0; y < 64; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final value = pixel.r / 255.0;
        final idx = (y * resized.width + x) * 3;
        normalized[idx] = value;     // R
        normalized[idx + 1] = value; // G
        normalized[idx + 2] = value; // B
      }
    }
    
    return normalized.reshape([1, 3, 64, resized.width]);
  }
  
  String decodeCTC(List<dynamic> output) {
    // CTC decoding: remove blanks and duplicates
    final decoded = <String>[];
    int prevIdx = -1;
    
    for (final logits in output[0]) {
      final idx = logits.indexOf(logits.reduce(max));
      if (idx != 0 && idx != prevIdx) {  // 0 = blank
        decoded.add(charset[idx]);
      }
      prevIdx = idx;
    }
    
    return decoded.join();
  }
  
  double? _extractAmount(String text) {
    // Regex từ old OCR service
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
    // Regex date patterns (DD/MM/YYYY, etc.)
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
            int.parse(match.group(1)!)
          );
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
}
```

#### 3.4 Update AddTransactionScreen

```dart
// Thay đổi trong lib/screens/transaction/add_transaction_screen.dart

// Old
final _ocrService = OCRService();  // Google ML Kit

// New
final _ocrService = CustomOCRService();  // Custom model

// _scanFromCamera() và _pickFromGallery() không cần thay đổi gì!
// Vì interface giống nhau
```

#### 3.5 Test

```bash
flutter clean
flutter pub get
flutter run
```

**Test cases:**
1. Chụp ảnh hóa đơn từ camera
2. Chọn ảnh hóa đơn từ gallery
3. Verify số tiền và ngày được trích xuất đúng

---

## 📊 So Sánh: ML Kit vs Custom Model

| Feature | Google ML Kit | Custom Model |
|---------|---------------|--------------|
| **Accuracy (Vietnamese)** | 70-80% | 85-95% (sau training tốt) |
| **Model Size** | ~10MB (tải runtime) | ~25MB (embed trong app) |
| **Offline** | ❌ Cần internet lần đầu | ✅ Hoàn toàn offline |
| **Cost** | Free (có giới hạn) | Free (100% sở hữu) |
| **Customization** | ❌ Không thể | ✅ Fine-tune được |
| **Invoice-specific** | ❌ General OCR | ✅ Trained cho hóa đơn VN |
| **Speed** | ~500ms | ~200-500ms |

---

## 🔧 Troubleshooting

### Issue 1: Training Loss không giảm

**Nguyên nhân:**
- Learning rate quá cao
- Dataset quality kém
- Annotation format sai

**Giải pháp:**
```python
# Giảm learning rate
LEARNING_RATE = 0.0001  # thay vì 0.0005

# Kiểm tra dataset
print(train_dataset[0])  # Xem sample có đúng không
```

### Issue 2: CTC Loss = NaN

**Nguyên nhân:**
- `output_lengths` < `text_lengths`
- Vocabulary thiếu ký tự

**Giải pháp:**
```python
# Add trong training loop
print(f"Output lengths: {output_lengths}")
print(f"Text lengths: {text_lengths}")
assert all(output_lengths >= text_lengths)

# Thêm gradient clipping
torch.nn.utils.clip_grad_norm_(model.parameters(), 5.0)
```

### Issue 3: TFLite conversion failed

**Giải pháp:**
```bash
# Use older opset
torch.onnx.export(..., opset_version=11)

# Or use direct PyTorch to TFLite
pip install ai_edge_torch
```

### Issue 4: Flutter model loading error

**Giải pháp:**
```yaml
# Verify asset path
flutter:
  assets:
    - assets/models/vietnamese_ocr_model.tflite  # ✅ Correct

# NOT:
    - assets/models/  # ❌ Wrong
```

**Check file exists:**
```bash
ls -lh assets/models/vietnamese_ocr_model.tflite
```

---

## 📈 Performance Optimization

### Training Phase:

1. **Data Augmentation:**
   ```python
   # Tăng cường augmentation
   preprocessor.augment_probability = 0.5
   ```

2. **Learning Rate Scheduling:**
   ```python
   scheduler = CosineAnnealingLR(optimizer, T_max=NUM_EPOCHS)
   ```

3. **Mixed Precision Training:**
   ```python
   from torch.cuda.amp import autocast, GradScaler
   scaler = GradScaler()
   
   with autocast():
       output = model(images)
       loss = criterion(...)
   scaler.scale(loss).backward()
   scaler.step(optimizer)
   ```

### Inference Phase:

1. **Model Quantization:**
   ```python
   # TFLite với INT8 quantization
   converter.optimizations = [tf.lite.Optimize.DEFAULT]
   converter.target_spec.supported_types = [tf.int8]
   ```

2. **Input Size Optimization:**
   ```python
   # Giảm img_height xuống 32 (nếu accuracy chấp nhận được)
   preprocessor = OCRPreprocessor(img_height=32)
   ```

3. **Caching:**
   ```dart
   // Cache interpreter instance
   static Interpreter? _cachedInterpreter;
   ```

---

## 🎯 Next Steps

### Short-term (1-2 tuần):

- [x] Train baseline model
- [ ] Test trên 100 hóa đơn thật
- [ ] Fine-tune với dữ liệu riêng
- [ ] Integrate vào Flutter app
- [ ] A/B test vs ML Kit

### Mid-term (1 tháng):

- [ ] Thêm detection model (tìm vùng text trước)
- [ ] Multi-line OCR (xử lý cả hóa đơn)
- [ ] Auto-categorization (dựa vào tên cửa hàng)
- [ ] Receipt template matching
- [ ] Cloud backup cho failed cases

### Long-term (3 tháng):

- [ ] Collect user feedback → retrain
- [ ] Support English receipts
- [ ] Table extraction (line items)
- [ ] Merchant database (auto-fill)
- [ ] Real-time OCR (video stream)

---

## 📞 Support & Contact

**Bugs & Issues:**
- GitHub Issues: [github.com/khanhhtapcode/FinTrack-App/issues](https://github.com/khanhhtapcode/FinTrack-App/issues)
- Email: [your-email@example.com](mailto:your-email@example.com)

**Documentation:**
- Main README: `/README.md`
- OCR Training Guide: `/OCR_TRAINING_GUIDE.md`
- OCR Troubleshooting: `/OCR_TROUBLESHOOTING.md`

**Resources:**
- [Dataset: MC-OCR 2021](https://www.kaggle.com/datasets/domixi1989/vietnamese-receipts-mc-ocr-2021)
- [CRNN Paper](https://arxiv.org/abs/1507.05717)
- [TFLite Flutter](https://pub.dev/packages/tflite_flutter)

---

## 📄 License

MIT License - Free to use and modify

---

**Last updated:** November 17, 2025  
**Version:** 1.0  
**Author:** KHANH - FinTracker OCR Project

**🎉 Good luck với training! 🚀**
