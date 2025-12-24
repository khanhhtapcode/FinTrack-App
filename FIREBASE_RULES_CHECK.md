# Kiểm tra Firebase Rules

## Bước 1: Check Firestore Rules

Vào Firebase Console > Firestore Database > Rules

Rules hiện tại phải cho phép đọc users:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write to users collection
    match /users/{userId} {
      allow read: if true;  // Hoặc điều kiện phù hợp
      allow write: if request.auth != null || true;
    }
    
    // Các collections khác
    match /transactions/{transId} {
      allow read, write: if true;
    }
    
    match /budgets/{budgetId} {
      allow read, write: if true;
    }
    
    match /wallets/{walletId} {
      allow read, write: if true;
    }
    
    match /categories/{categoryId} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ LƯU Ý:** `allow read: if true;` cho phép đọc tất cả (dùng cho dev/testing). 
Trong production nên dùng: `allow read: if request.auth != null;`

## Bước 2: Check document structure

Click vào một document trong Firebase Console và verify có các fields:
- `email` (String)
- `id` (String)
- `firstName` (String)
- `lastName` (String)
- `passwordHash` (String)
- `isVerified` (boolean)
- `createdAt` (String - ISO format)

## Bước 3: Test với debug logs

Sau khi update rules, chạy app và xem logs:

1. Mở Debug Console trong VS Code
2. Chạy app trên máy mới
3. Thử đăng nhập
4. Xem logs để biết:
   - "🔍 [Firebase] Searching for user with email: ..."
   - "📊 [Firebase] Found X documents"
   - Nếu có lỗi: error message chi tiết

## Bước 4: Verify Firebase initialization

Check trong Debug Console có dòng này không:
- `✅ Cloud sync completed for user ...`

Nếu không có hoặc có lỗi "Firebase init skipped", cần check:
1. File `google-services.json` có đúng trong `android/app/`
2. File `.env` có tồn tại
3. Firebase đã được enable trong project
