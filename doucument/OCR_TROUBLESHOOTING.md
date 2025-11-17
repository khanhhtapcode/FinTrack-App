# 🔧 Hướng dẫn Fix OCR không hoạt động

## ❌ Vấn đề: OCR không scan được hóa đơn

### 🔍 Các nguyên nhân phổ biến:

---

## 1️⃣ **Chưa cấp quyền Camera/Photos**

### Android:
```
Settings → Apps → FinTracker → Permissions
→ Bật Camera
→ Bật Photos/Storage
```

### iOS:
```
Settings → FinTracker
→ Camera: Allow
→ Photos: Allow
```

### Trong code (đã có):
File `pubspec.yaml` đã có `permission_handler: ^11.3.1`

---

## 2️⃣ **ML Kit chưa được setup đúng**

### Android - Kiểm tra `android/app/build.gradle.kts`:

Đảm bảo có:
```kotlin
android {
    defaultConfig {
        minSdk = 21  // ML Kit yêu cầu tối thiểu Android 5.0
    }
}
```

### iOS - Kiểm tra `ios/Podfile`:

Thêm dòng này (nếu chưa có):
```ruby
platform :ios, '12.0'  # ML Kit yêu cầu tối thiểu iOS 12
```

Sau đó chạy:
```bash
cd ios
pod install
cd ..
```

---

## 3️⃣ **Test OCR đơn giản**

### Bước 1: Chạy app
```bash
flutter run
```

### Bước 2: Thêm giao dịch
1. Click nút **+** (Add)
2. Click icon **📷 Camera** ở góc trên
3. Chọn **"Quét từ Camera"** hoặc **"Chọn từ thư viện"**

### Bước 3: Xem log
Nếu có lỗi, check console:
```bash
# Xem log realtime
flutter logs
```

Tìm dòng có:
- `Camera scan error:`
- `Gallery pick error:`
- `Error scanning from camera:`
- `Error picking from gallery:`

---

## 4️⃣ **Permissions không được cấp**

### Cách 1: Uninstall và install lại app
```bash
flutter clean
flutter run
```
→ App sẽ hỏi quyền lại lần đầu

### Cách 2: Vào Settings cấp quyền thủ công
- **Android**: Settings → Apps → FinTracker → Permissions
- **iOS**: Settings → FinTracker

---

## 5️⃣ **Test với ảnh mẫu**

### Tải ảnh hóa đơn mẫu:
1. Tìm một hóa đơn có:
   - ✅ Số tiền rõ ràng (VD: "150,000 VND")
   - ✅ Text "Tổng" hoặc "Total"
   - ✅ Ảnh sáng, không mờ

2. Lưu vào thư viện ảnh
3. Dùng "Chọn từ thư viện" để test

### Ví dụ format hóa đơn tốt:
```
--------------------------------
        CỬA HÀNG ABC
--------------------------------
Cà phê sữa        30,000
Bánh mì           25,000
--------------------------------
Tổng cộng:       150,000 VND
--------------------------------
```

---

## 6️⃣ **Check dependencies**

### Xem phiên bản ML Kit:
File `pubspec.yaml`:
```yaml
dependencies:
  google_mlkit_text_recognition: ^0.13.1  # ✅ OK
  image_picker: ^1.1.2                     # ✅ OK
  permission_handler: ^11.3.1              # ✅ OK
```

### Update nếu cần:
```bash
flutter pub upgrade google_mlkit_text_recognition
flutter pub upgrade image_picker
flutter clean
flutter run
```

---

## 7️⃣ **Error messages mới**

Giờ app sẽ hiển thị lỗi chi tiết hơn:

### Nếu không mở được camera:
```
Không thể mở camera.

Vui lòng kiểm tra:
• Quyền truy cập camera
• Camera có hoạt động không
```

### Nếu không chọn được ảnh:
```
Không thể chọn ảnh.

Vui lòng kiểm tra:
• Quyền truy cập thư viện ảnh
• Có ảnh trong thư viện không
```

### Nếu có lỗi khác:
```
Lỗi khi quét hóa đơn

Chi tiết: [error message]

Thử:
• Cấp quyền camera trong Settings
• Khởi động lại ứng dụng
```

---

## 8️⃣ **Debug mode**

### Enable verbose logging:
Trong `lib/services/ocr_service.dart`, tất cả các catch block đã có:
```dart
catch (e) {
  print('Error scanning from camera: $e');
  return null;
}
```

### Xem log chi tiết:
```bash
# Android
flutter logs | grep -i "ocr\|camera\|error"

# iOS
flutter logs | grep -i "ocr\|camera\|error"

# Windows (PowerShell)
flutter logs | Select-String "ocr|camera|error" -CaseSensitive:$false
```

---

## 9️⃣ **Test trên thiết bị thật**

⚠️ **Lưu ý**: OCR hoạt động tốt nhất trên **thiết bị thật**, không phải emulator!

### Lý do:
- Emulator không có camera thật
- ML Kit cần hardware acceleration
- Gallery trên emulator có thể thiếu ảnh

### Khuyến nghị:
```bash
# Connect thiết bị qua USB
flutter devices

# Run trên thiết bị thật
flutter run -d <device-id>
```

---

## 🔟 **Fallback: Nhập thủ công**

Nếu OCR vẫn không hoạt động, user có thể:
1. Nhập số tiền thủ công
2. Chọn danh mục
3. Thêm ghi chú (ghi thông tin từ hóa đơn)

OCR chỉ là tính năng **hỗ trợ**, không bắt buộc!

---

## ✅ Checklist khi báo lỗi:

Trước khi báo lỗi, kiểm tra:
- [ ] App version: `flutter --version`
- [ ] Đã cấp quyền Camera: YES/NO
- [ ] Đã cấp quyền Photos: YES/NO
- [ ] Test trên Emulator hay thiết bị thật?
- [ ] OS version (Android X.X / iOS X.X)
- [ ] Error message trong console
- [ ] Screenshot lỗi

---

## 📞 Liên hệ Support

Nếu vẫn không được:
1. Chụp screenshot lỗi
2. Copy error message từ console
3. Gửi cho KHANH qua GitHub Issues

---

**Last updated**: 17/11/2025
