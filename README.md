# 💰 FinTracker - Expense Tracker App

Ứng dụng quản lý chi tiêu cá nhân với tính năng OCR quét hóa đơn bằng Gemini AI, thống kê tài chính, và Admin Panel.

## 📋 Mục lục
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt cho người mới](#-cài-đặt-cho-người-mới-pull-project)
- [Chạy ứng dụng](#-chạy-ứng-dụng)
- [Tính năng chính](#-tính-năng-chính)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Tài khoản Admin](#-tài-khoản-admin)
- [Troubleshooting](#-troubleshooting)

---

## 🛠️ Yêu cầu hệ thống

### Bắt buộc phải có:
- **Flutter SDK**: >= 3.8.1
- **Dart SDK**: >= 3.8.1
- **Android Studio** hoặc **VS Code** với Flutter extension
- **Git**
- **Node.js**: v22+ (cho Firebase Functions)
- **Firebase CLI**: Để deploy Cloud Functions

### Kiểm tra version:
```bash
flutter --version
dart --version
node --version
firebase --version
```

---

## 🚀 Cài đặt cho người mới (Pull Project)

### Bước 1: Clone Repository
```bash
git clone https://github.com/khanhhtapcode/FinTrack-App.git
cd FinTrack-App
```

### Bước 2: Cài đặt Dependencies
```bash
# Cài Flutter packages
flutter pub get

# Cài Firebase Functions dependencies (nếu cần)
cd functions
npm install
cd ..
```

### Bước 3: Cấu hình Gemini API Key ⭐ MỚI
⚠️ **BẮT BUỘC** để sử dụng tính năng quét hóa đơn OCR!

1. Lấy API key từ [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Tạo file `.env` ở thư mục root project:
```bash
# Tạo file .env
echo GEMINI_API_KEY=your_actual_api_key_here > .env
```

3. Thay `your_actual_api_key_here` bằng API key thật của bạn

**Lưu ý:** File `.env` đã được thêm vào `.gitignore`, không lo bị lộ key!

### Bước 4: **QUAN TRỌNG** - Generate Code
⚠️ **Các file `.g.dart` KHÔNG được push lên Git và cần generate lại!**

```bash
# Generate Hive TypeAdapters
flutter pub run build_runner build --delete-conflicting-outputs
```

Lệnh này sẽ tạo ra:
- `lib/models/user.g.dart`
- `lib/models/transaction.g.dart`

**Nếu không chạy lệnh này, app sẽ bị lỗi:**
```
Error: Cannot find 'UserAdapter'
Error: Cannot find 'TransactionAdapter'
```

### Bước 5: Cấu hình Firebase (Nếu chưa có)

#### Android:
1. Download `google-services.json` từ Firebase Console
2. Đặt vào: `android/app/google-services.json`

#### iOS:
1. Download `GoogleService-Info.plist` từ Firebase Console
2. Đặt vào: `ios/Runner/GoogleService-Info.plist`

⚠️ **Lưu ý:** Các file Firebase config đã có trong project, KHÔNG cần download lại trừ khi thay đổi Firebase project.

### Bước 6: Setup Firebase Functions (Optional)
```bash
# Đăng nhập Firebase
firebase login

# Chọn project
firebase use --add

# Deploy functions (nếu cần)
cd functions
npm install
firebase deploy --only functions
cd ..
```

---

## ▶️ Chạy ứng dụng

### Chạy trên Emulator/Device:
```bash
# Kiểm tra devices
flutter devices

# Chạy app
flutter run
```

### Chạy trên Chrome (Web):
```bash
flutter run -d chrome
```

### Build APK (Android):
```bash
flutter build apk --release
```

### Build iOS:
```bash
flutter build ios --release
```

---

## ✨ Tính năng chính

### 🔐 Authentication
- Đăng ký tài khoản với email
- Xác thực OTP qua email (Firebase Functions)
- Đăng nhập / Đăng xuất
- **Admin Panel** riêng biệt

### 💰 Quản lý giao dịch
- **3 loại giao dịch**: Chi tiêu, Thu nhập, Vay/Nợ
- **16 danh mục chi tiêu** + **6 thu nhập** + **4 vay/nợ**
- Thêm/Sửa/Xóa giao dịch
- Chọn ngày giao dịch
- Ghi chú cho mỗi giao dịch

### 📸 OCR Quét hóa đơn ⭐ GEMINI AI
- Quét từ **Camera** hoặc **Gallery**
- Tự động nhận diện: **Số tiền**, **Ngày tháng**, **Danh mục**, **Tên cửa hàng**, **Danh sách món**
- Sử dụng **Gemini 1.5 Pro Vision API** (Google AI)
- Hỗ trợ **tiếng Việt có dấu** đầy đủ
- **Confidence score** đánh giá độ tin cậy
- Xử lý ảnh trên **isolate** để tránh lag UI
- **Timeout protection** và retry logic

📖 **Xem hướng dẫn chi tiết:** [GEMINI_OCR_SETUP.md](./GEMINI_OCR_SETUP.md)

### 📊 Thống kê & Báo cáo
- Tổng chi/thu hiện tại
- **Biểu đồ cột 6 tháng gần nhất**
- Chọn năm để xem thống kê
- **Giao dịch gần đây** với icon và màu sắc
- Balance card với gradient

### 🎨 UI/UX Improvements
- **Responsive design** cho màn hình nhỏ (<360px)
- **SingleChildScrollView** tránh overflow khi keyboard xuất hiện
- **RefreshIndicator** kéo xuống để làm mới
- **Loading states** với CircularProgressIndicator
- **Error handling** với dialog và snackbar thân thiện

### 👑 Admin Panel
- Quản lý tất cả users
- Quản lý tất cả transactions
- Xóa dữ liệu
- Debug database

---

## 📁 Cấu trúc dự án

```
lib/
├── main.dart                        # Entry point
├── config/
│   ├── constants.dart               # App constants
│   └── theme.dart                   # Theme & colors
├── models/
│   ├── user.dart                    # User model + HiveType
│   ├── user.g.dart                  # 🔄 Generated by build_runner
│   ├── transaction.dart             # Transaction model + HiveType
│   ├── transaction.g.dart           # 🔄 Generated by build_runner
│   └── receipt_data.dart            # ⭐ OCR result model
├── services/
│   ├── auth_service.dart            # Authentication logic
│   ├── transaction_service.dart     # Transaction CRUD
│   ├── ocr_service.dart             # ⭐ OCR wrapper for Gemini Vision API
│   ├── gemini_ocr_service.dart      # ⭐ Gemini Vision API integration
│   └── hive_debug_service.dart      # Debug utilities
├── screens/
│   ├── splash/                      # Splash screen
│   ├── onboarding/                  # Onboarding flow
│   ├── auth/                        # Login, Register, OTP
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── otp_screen.dart
│   ├── home/                        # Home screen
│   ├── transaction/                 # Add/Edit transactions
│   │   └── add_transaction_screen.dart
│   ├── admin/                       # Admin panel
│   │   └── admin_home_screen.dart
│   └── debug/                       # Debug screen
│       └── debug_screen.dart
├── widgets/                         # Reusable widgets
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── expense_card.dart
│   ├── balance_card_widget.dart     # ⭐ Balance display
│   ├── chart_widget.dart            # ⭐ Monthly expense chart
│   └── recent_transactions_widget.dart  # ⭐ Recent transactions list
└── providers/                       # State management (Provider)

functions/                           # Firebase Cloud Functions
├── index.js                         # Send OTP email
└── package.json                     # Node dependencies

assets/
├── icons/                           # Icon assets
└── images/                          # Image assets

.env                                 # ⭐ Gemini API key (KHÔNG push lên Git)
```

### 🔄 Generated Files (KHÔNG push lên Git)
Các file này được generate bởi `build_runner`:
- `lib/models/user.g.dart`
- `lib/models/transaction.g.dart`
- `lib/models/*.g.dart` (mọi file có `@HiveType`)

**Lý do:** 
- File generated thay đổi theo môi trường
- Dễ conflict khi nhiều người code
- Có thể generate lại bất cứ lúc nào

---

## 🔐 Tài khoản Admin

### Thông tin đăng nhập:
```
Email: 
Password: 
```

### Quyền Admin:
- ✅ Xem tất cả users đã đăng ký
- ✅ Xem tất cả transactions
- ✅ Xóa users/transactions
- ✅ Xóa toàn bộ database
- ✅ Debug session data

### Cách vào Admin Panel:
1. Mở app → Màn hình Login
2. Nhập email: ``
3. Nhập password: ``
4. Tự động chuyển đến Admin Panel

📖 **Xem thêm:** `ADMIN_GUIDE.md`

---

## 📦 Dependencies chính

| Package | Version | Mục đích |
|---------|---------|----------|
| `hive` | ^2.2.3 | NoSQL database local |
| `hive_flutter` | ^1.1.0 | Hive cho Flutter |
| `provider` | ^6.1.1 | State management |
| `firebase_core` | ^3.6.0 | Firebase initialization |
| `cloud_functions` | ^5.1.3 | Call Cloud Functions |
| `image_picker` | ^1.1.2 | Chọn ảnh từ camera/gallery |
| `google_generative_ai` | ^0.4.6 | ⭐ Gemini Vision API SDK |
| `flutter_dotenv` | ^5.2.1 | ⭐ Load environment variables |
| `http` | ^1.2.2 | ⭐ HTTP client for API calls |
| `image` | ^4.0.0 | Xử lý ảnh cho OCR |
| `permission_handler` | ^11.3.1 | Xin permission |
| `uuid` | ^4.5.1 | Generate unique ID |
| `fl_chart` | ^0.66.0 | Vẽ charts |
| `intl` | ^0.19.0 | Format date/number |
| `mailer` | ^6.0.1 | Email service |
| `crypto` | ^3.0.3 | Mã hóa dữ liệu |
| `smooth_page_indicator` | ^1.2.1 | Onboarding indicator |

### Dev Dependencies:
| Package | Version | Mục đích |
|---------|---------|----------|
| `hive_generator` | ^2.0.1 | Generate TypeAdapters |
| `build_runner` | ^2.4.7 | Code generation tool |

---

## 🐛 Troubleshooting

### ❌ Lỗi: GEMINI_API_KEY not found
**Nguyên nhân:** Chưa tạo file `.env` hoặc chưa điền API key

**Giải pháp:**
1. Tạo file `.env` ở root project
2. Thêm dòng: `GEMINI_API_KEY=your_actual_key_here`
3. Lấy key từ: https://makersuite.google.com/app/apikey
4. **Restart app hoàn toàn** (không chỉ hot reload)

---

### ❌ Lỗi: models/gemini-1.5-pro is not found
**Nguyên nhân:** Model name sai hoặc API key không hợp lệ

**Giải pháp:**
- Kiểm tra API key có đúng format không
- Đảm bảo đã enable Gemini API trong Google Cloud Console
- Model name hiện tại: `gemini-1.5-pro` (đã cập nhật trong code)

---

### ❌ App crash khi vào HomeScreen
**Nguyên nhân:** Widget chart hoặc transactions gặp lỗi null data

**Giải pháp:**
- Đảm bảo có ít nhất 1 transaction trong database
- Kiểm tra icon assets có đầy đủ trong `assets/icons/`
- Restart app để reload data

---
**Nguyên nhân:** Chưa generate code cho Hive TypeAdapters

**Giải pháp:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### ❌ Lỗi: MissingPluginException
**Nguyên nhân:** Flutter plugins chưa được build

**Giải pháp:**
```bash
flutter clean
flutter pub get
flutter run
```

---

### ❌ Lỗi: Firebase not initialized
**Nguyên nhân:** Thiếu file `google-services.json` hoặc `GoogleService-Info.plist`

**Giải pháp:**
1. Download từ Firebase Console
2. Đặt đúng vị trí (xem Bước 4 phía trên)
3. Chạy lại app

---

### ❌ Lỗi: Permission denied (Camera/Photos)
**Nguyên nhân:** Chưa cấp quyền cho app

**Giải pháp:**
- **Android**: Vào Settings → Apps → FinTracker → Permissions
- **iOS**: Settings → FinTracker → Enable Camera & Photos

---

### ❌ Lỗi: Build runner conflicts
**Giải pháp:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### ❌ App bị crash khi mở Debug Screen
**Nguyên nhân:** Chưa init Hive box

**Giải pháp:** Restart app, Hive sẽ tự động init trong `main.dart`

---

## 📚 Tài liệu bổ sung

- 📖 **GEMINI_OCR_SETUP.md** - ⭐ Hướng dẫn setup Gemini Vision API OCR
- 📖 **ADMIN_GUIDE.md** - Hướng dẫn sử dụng Admin Panel
- 📖 **TRANSACTION_STORAGE_GUIDE.md** - Chi tiết về cách lưu trữ giao dịch
- 📖 **BACKEND_SETUP.md** - Setup Firebase Backend
- 📖 **TEST_EMAIL.md** - Test gửi OTP email

---

## 🔧 Scripts hữu ích

### Clean & Rebuild:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Generate code watch mode (auto-generate khi có thay đổi):
```bash
flutter pub run build_runner watch
```

### Check for outdated packages:
```bash
flutter pub outdated
```

### Analyze code:
```bash
flutter analyze
```

### Format code:
```bash
flutter format lib/
```

---

## 📝 Checklist cho người mới

- [ ] Clone repository
- [ ] Cài Flutter SDK (>= 3.8.1)
- [ ] Chạy `flutter pub get`
- [ ] ⭐ **Tạo file `.env` và thêm `GEMINI_API_KEY`** (BẮT BUỘC cho OCR)
- [ ] **Chạy `build_runner` để generate `.g.dart` files** ⚠️
- [ ] Kiểm tra file `google-services.json` có trong `android/app/`
- [ ] Chạy `flutter run` để test
- [ ] Login với user thường để test
- [ ] Login với admin để test Admin Panel
- [ ] Test thêm giao dịch
- [ ] ⭐ **Test OCR quét hóa đơn** (chụp ảnh hoặc chọn từ thư viện)
- [ ] Kiểm tra biểu đồ và giao dịch gần đây hiển thị đúng

📖 **Hướng dẫn chi tiết OCR:** [GEMINI_OCR_SETUP.md](./GEMINI_OCR_SETUP.md)

---

## 👥 Team

- **Developer**: KHANH HUY QUANG HOANG
- **Repository**: [github.com/khanhhtapcode/FinTrack-App](https://github.com/khanhhtapcode/FinTrack-App)

---

## 📄 License

This project is private and not for public distribution.

---

## 🆘 Hỗ trợ

Nếu gặp vấn đề, hãy:
1. Đọc phần **Troubleshooting** ở trên
2. Check file `ADMIN_GUIDE.md` hoặc `TRANSACTION_STORAGE_GUIDE.md`
3. Liên hệ KHANH qua GitHub Issues

---

**Last updated:** 19/11/2025  
**Version:** 2.0.0 (Gemini Vision AI OCR + UI Improvements)
