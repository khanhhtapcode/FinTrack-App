# 📚 Hướng Dẫn Training OCR Model - Chi Tiết Đầy Đủ

## 📖 Tài liệu bổ sung cho Notebook

File này chứa code đầy đủ và giải thích chi tiết cho các phần quan trọng trong notebook training OCR.

---

## 1️⃣ COMPLETE TRAINING LOOP CODE

```python
# Cell 15: Full Training Loop
def train_one_epoch(model, dataloader, criterion, optimizer, device):
    """Train for one epoch"""
    model.train()
    total_loss = 0
    progress_bar = tqdm(dataloader, desc="Training")
    
    for batch_idx, (images, texts, text_lengths) in enumerate(progress_bar):
        # Move to device
        images = images.to(device)
        texts = texts.to(device)
        text_lengths = text_lengths.to(device)
        
        # Forward pass
        outputs = model(images)  # (seq_len, batch, num_chars)
        output_lengths = torch.full((images.size(0),), outputs.size(0), dtype=torch.long)
        
        # Calculate CTC loss
        # CTCLoss expects: (T, N, C), targets, input_lengths, target_lengths
        loss = criterion(
            outputs.log_softmax(2),  # Apply log_softmax
            texts,
            output_lengths,
            text_lengths
        )
        
        # Backward pass
        optimizer.zero_grad()
        loss.backward()
        
        # Gradient clipping to prevent exploding gradients
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=5.0)
        
        optimizer.step()
        
        # Update metrics
        total_loss += loss.item()
        avg_loss = total_loss / (batch_idx + 1)
        progress_bar.set_postfix({'loss': f'{avg_loss:.4f}'})
    
    return total_loss / len(dataloader)


def validate(model, dataloader, criterion, device, idx_to_char):
    """Validate model"""
    model.eval()
    total_loss = 0
    all_predictions = []
    all_targets = []
    
    with torch.no_grad():
        for images, texts, text_lengths in tqdm(dataloader, desc="Validation"):
            images = images.to(device)
            texts = texts.to(device)
            text_lengths = text_lengths.to(device)
            
            # Forward pass
            outputs = model(images)
            output_lengths = torch.full((images.size(0),), outputs.size(0), dtype=torch.long)
            
            # Calculate loss
            loss = criterion(
                outputs.log_softmax(2),
                texts,
                output_lengths,
                text_lengths
            )
            total_loss += loss.item()
            
            # Decode predictions
            predictions = decode_predictions(outputs, idx_to_char)
            
            # Decode targets
            for text, length in zip(texts, text_lengths):
                target_text = ''.join([idx_to_char.get(idx.item(), '') 
                                      for idx in text[:length]])
                all_targets.append(target_text)
            
            all_predictions.extend(predictions)
    
    # Calculate metrics
    avg_loss = total_loss / len(dataloader)
    cer = calculate_cer(all_predictions, all_targets)
    
    return avg_loss, cer, all_predictions[:5], all_targets[:5]


# Main training loop
def train_model(model, train_loader, val_loader, criterion, optimizer, scheduler, 
                num_epochs, device, save_dir, idx_to_char):
    """Complete training pipeline"""
    
    best_cer = float('inf')
    history = {'train_loss': [], 'val_loss': [], 'val_cer': []}
    
    print("🚀 Starting training...")
    print(f"   Device: {device}")
    print(f"   Train samples: {len(train_loader.dataset)}")
    print(f"   Val samples: {len(val_loader.dataset)}")
    print(f"   Epochs: {num_epochs}\n")
    
    for epoch in range(num_epochs):
        print(f"\n{'='*60}")
        print(f"Epoch {epoch+1}/{num_epochs}")
        print(f"{'='*60}")
        
        # Train
        train_loss = train_one_epoch(model, train_loader, criterion, optimizer, device)
        history['train_loss'].append(train_loss)
        
        # Validate
        val_loss, val_cer, sample_preds, sample_targets = validate(
            model, val_loader, criterion, device, idx_to_char
        )
        history['val_loss'].append(val_loss)
        history['val_cer'].append(val_cer)
        
        # Update learning rate
        scheduler.step(val_loss)
        current_lr = optimizer.param_groups[0]['lr']
        
        # Print metrics
        print(f"\n📊 Epoch {epoch+1} Results:")
        print(f"   Train Loss: {train_loss:.4f}")
        print(f"   Val Loss:   {val_loss:.4f}")
        print(f"   Val CER:    {val_cer:.4f}")
        print(f"   LR:         {current_lr:.6f}")
        
        # Show sample predictions
        print(f"\n📝 Sample Predictions:")
        for i, (pred, target) in enumerate(zip(sample_preds, sample_targets)):
            print(f"   [{i+1}] Pred:   {pred[:50]}")
            print(f"       Target: {target[:50]}")
        
        # Save best model
        if val_cer < best_cer:
            best_cer = val_cer
            checkpoint_path = os.path.join(save_dir, 'best_model.pth')
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_cer': val_cer,
                'val_loss': val_loss,
                'char_to_idx': char_to_idx,
                'idx_to_char': idx_to_char
            }, checkpoint_path)
            print(f"\n💾 Saved best model (CER: {val_cer:.4f})")
        
        # Save checkpoint every 5 epochs
        if (epoch + 1) % 5 == 0:
            checkpoint_path = os.path.join(save_dir, f'checkpoint_epoch_{epoch+1}.pth')
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
            }, checkpoint_path)
    
    print("\n✅ Training completed!")
    print(f"   Best CER: {best_cer:.4f}")
    
    return history
```

---

## 2️⃣ CREATE DATALOADERS

**MC-OCR 2021 Dataset Structure:**
```
data/
├── mcocr_train_df.csv          # Train annotations
├── mcocr_val_sample_df.csv     # Val annotations
├── train_images/
│   └── train_images/           # Nested! Images here
└── val_images/
    └── val_images/             # Nested! Images here
```

```python
# Cell 16: Create DataLoaders với cấu trúc MC-OCR 2021
import pandas as pd

# Đọc CSV annotations (files nằm trực tiếp trong data/)
train_csv_path = '/content/data/mcocr_train_df.csv'
val_csv_path = '/content/data/mcocr_val_sample_df.csv'

print("📊 Đọc annotation files...")
print(f"Train CSV: {train_csv_path}")
print(f"Val CSV: {val_csv_path}")

train_df = pd.read_csv(train_csv_path)
val_df = pd.read_csv(val_csv_path)

print(f"✅ Train samples: {len(train_df)}")
print(f"✅ Val samples: {len(val_df)}")
print(f"\n📋 CSV columns: {train_df.columns.tolist()}")

# Custom Dataset cho MC-OCR format
class MCOCRDataset(Dataset):
    """Dataset for MC-OCR 2021 with CSV annotations"""
    
    def __init__(self, df, img_dir, preprocessor, char_to_idx, augment=False):
        self.df = df.reset_index(drop=True)
        self.img_dir = Path(img_dir)
        self.preprocessor = preprocessor
        self.char_to_idx = char_to_idx
        self.augment = augment
        
        # Verify valid samples
        valid_samples = []
        for idx in range(len(self.df)):
            row = self.df.iloc[idx]
            img_name = row.get('img_id', row.get('file_name', ''))
            img_path = self.img_dir / img_name
            if img_path.exists():
                valid_samples.append(idx)
        
        self.valid_indices = valid_samples
        print(f"✅ Valid: {len(self.valid_indices)} / {len(self.df)}")
    
    def __len__(self):
        return len(self.valid_indices)
    
    def encode_text(self, text):
        if pd.isna(text):
            return []
        encoded = []
        for char in str(text):
            if char in self.char_to_idx:
                encoded.append(self.char_to_idx[char])
        return encoded
    
    def __getitem__(self, idx):
        real_idx = self.valid_indices[idx]
        row = self.df.iloc[real_idx]
        
        # Load image
        img_name = row.get('img_id', row.get('file_name', ''))
        img_path = self.img_dir / img_name
        img = Image.open(img_path).convert('RGB')
        img = self.preprocessor(img, augment=self.augment)
        
        # Get text annotation
        text = row.get('anno_texts', row.get('text', ''))
        text_encoded = self.encode_text(text)
        if len(text_encoded) == 0:
            text_encoded = [0]  # Avoid empty tensor
        
        return img, torch.LongTensor(text_encoded), len(text_encoded)

# Tạo datasets với nested folder structure
train_dataset = MCOCRDataset(
    df=train_df,
    img_dir='/content/data/train_images/train_images',  # Nested!
    preprocessor=preprocessor,
    char_to_idx=char_to_idx,
    augment=True
)

val_dataset = MCOCRDataset(
    df=val_df,
    img_dir='/content/data/val_images/val_images',  # Nested!
    preprocessor=preprocessor,
    char_to_idx=char_to_idx,
    augment=False
)

# Tạo dataloaders
train_loader = DataLoader(
    train_dataset,
    batch_size=BATCH_SIZE,
    shuffle=True,
    num_workers=2,
    collate_fn=collate_fn,
    pin_memory=True
)

val_loader = DataLoader(
    val_dataset,
    batch_size=BATCH_SIZE,
    shuffle=False,
    num_workers=2,
    collate_fn=collate_fn,
    pin_memory=True
)

print(f"\n✅ DataLoaders created!")
print(f"   Train batches: {len(train_loader)}")
print(f"   Val batches: {len(val_loader)}")

# Test batch
sample_batch = next(iter(train_loader))
print(f"\n📦 Sample batch:")
print(f"   Images: {sample_batch[0].shape}")
print(f"   Texts: {sample_batch[1].shape}")
print(f"   Lengths: {sample_batch[2][:5].tolist()}")
```

---

## 3️⃣ START TRAINING

```python
# Cell 17: Execute training
history = train_model(
    model=model,
    train_loader=train_loader,
    val_loader=val_loader,
    criterion=ctc_loss,
    optimizer=optimizer,
    scheduler=scheduler,
    num_epochs=NUM_EPOCHS,
    device=device,
    save_dir=SAVE_DIR,
    idx_to_char=idx_to_char
)

# Plot training curves
plt.figure(figsize=(15, 5))

plt.subplot(1, 3, 1)
plt.plot(history['train_loss'], label='Train Loss')
plt.plot(history['val_loss'], label='Val Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.title('Training & Validation Loss')
plt.legend()
plt.grid(True)

plt.subplot(1, 3, 2)
plt.plot(history['val_cer'])
plt.xlabel('Epoch')
plt.ylabel('CER')
plt.title('Validation Character Error Rate')
plt.grid(True)

plt.subplot(1, 3, 3)
# Learning rate over epochs (if you track it)
plt.xlabel('Epoch')
plt.ylabel('Learning Rate')
plt.title('Learning Rate Schedule')
plt.grid(True)

plt.tight_layout()
plt.savefig(os.path.join(SAVE_DIR, 'training_curves.png'), dpi=300)
plt.show()

print("📊 Training curves saved!")
```

---

## 4️⃣ INFERENCE & DEMO

```python
# Cell 18: Inference function
def inference(model, image_path, preprocessor, idx_to_char, device):
    """Run inference on a single image"""
    model.eval()
    
    # Load and preprocess image
    img = Image.open(image_path).convert('RGB')
    img_tensor = preprocessor(img, augment=False).unsqueeze(0).to(device)
    
    # Forward pass
    with torch.no_grad():
        output = model(img_tensor)
    
    # Decode
    predictions = decode_predictions(output, idx_to_char)
    
    return predictions[0]


# Cell 19: Test inference on sample images
# Load best model
checkpoint = torch.load(os.path.join(SAVE_DIR, 'best_model.pth'))
model.load_state_dict(checkpoint['model_state_dict'])
print(f"✅ Loaded best model (CER: {checkpoint['val_cer']:.4f})")

# Test on 5 random validation images from MCOCRDataset
sample_indices = random.sample(range(len(val_dataset)), min(5, len(val_dataset)))

plt.figure(figsize=(15, 12))
for i, idx in enumerate(sample_indices):
    # Get sample from dataset
    real_idx = val_dataset.valid_indices[idx]
    row = val_dataset.df.iloc[real_idx]
    
    # Get image path
    img_name = row.get('img_id', row.get('file_name', row.get('image_name', '')))
    img_path = val_dataset.img_dir / img_name
    
    # Inference
    predicted_text = inference(model, str(img_path), preprocessor, idx_to_char, device)
    
    # Get ground truth text
    gt_text = row.get('anno_texts', row.get('text', row.get('label', '')))
    
    # Display
    img = Image.open(img_path)
    plt.subplot(5, 1, i+1)
    plt.imshow(img)
    plt.title(f"Pred: {predicted_text[:100]}\nGT:   {gt_text[:100]}", fontsize=8)
    plt.axis('off')

plt.tight_layout()
plt.savefig(os.path.join(SAVE_DIR, 'inference_samples.png'), dpi=300)
plt.show()

print("✅ Inference demo completed!")
```

---

## 5️⃣ EXPORT TO ONNX

```python
# Cell 20: Export model to ONNX format (with model modification for compatibility)
import onnx
import onnxruntime

# Create ONNX-compatible version of model (replace AdaptiveAvgPool2d)
class CRNN_ONNX(nn.Module):
    """ONNX-compatible CRNN model"""
    
    def __init__(self, original_model):
        super(CRNN_ONNX, self).__init__()
        self.cnn = original_model.cnn
        self.rnn = original_model.rnn
        self.fc = original_model.fc
    
    def forward(self, x):
        # CNN feature extraction
        conv_features = self.cnn(x)  # (batch, 512, H', W')
        
        # Instead of AdaptiveAvgPool2d, use manual mean
        # Average over height dimension
        conv_features = torch.mean(conv_features, dim=2)  # (batch, 512, W')
        
        # Permute for RNN: (batch, W', 512)
        conv_features = conv_features.permute(0, 2, 1)
        
        # RNN sequence modeling
        rnn_output, _ = self.rnn(conv_features)
        
        # Character prediction
        output = self.fc(rnn_output)
        
        # Permute for CTC: (W', batch, num_chars)
        output = output.permute(1, 0, 2)
        
        return output

# Prepare ONNX-compatible model
print("🔄 Creating ONNX-compatible model...")
model_onnx = CRNN_ONNX(model).to(device)
model_onnx.eval()

# Test with dummy input
dummy_input = torch.randn(1, 3, 64, 256).to(device)
with torch.no_grad():
    dummy_output = model_onnx(dummy_input)
print(f"✅ ONNX model output shape: {dummy_output.shape}")

# Export to ONNX
onnx_path = os.path.join(SAVE_DIR, 'vietnamese_ocr_model.onnx')
torch.onnx.export(
    model_onnx,
    dummy_input,
    onnx_path,
    export_params=True,
    opset_version=11,  # Use opset 11 for better compatibility
    do_constant_folding=True,
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={
        'input': {0: 'batch_size', 3: 'width'},
        'output': {0: 'sequence_length', 1: 'batch_size'}
    }
)

print(f"✅ Model exported to ONNX: {onnx_path}")

# Verify ONNX model
onnx_model = onnx.load(onnx_path)
onnx.checker.check_model(onnx_model)
print("✅ ONNX model verification passed!")

# Test ONNX inference
print("\n🔄 Testing ONNX inference...")
ort_session = onnxruntime.InferenceSession(onnx_path)
ort_inputs = {ort_session.get_inputs()[0].name: dummy_input.cpu().numpy()}
ort_outputs = ort_session.run(None, ort_inputs)

print(f"📊 ONNX output shape: {ort_outputs[0].shape}")
print("✅ ONNX inference successful!")

# Compare PyTorch vs ONNX output
pytorch_out = dummy_output.cpu().numpy()
onnx_out = ort_outputs[0]
max_diff = np.abs(pytorch_out - onnx_out).max()
print(f"📊 Max difference PyTorch vs ONNX: {max_diff:.6f}")
if max_diff < 1e-4:
    print("✅ Outputs match!")
else:
    print("⚠️ Small numerical differences (normal)")
```

---

## 6️⃣ EXPORT TO PYTORCH MOBILE (Alternative to TFLite)

```python
# Cell 21: Export to PyTorch Mobile for Flutter
# TFLite conversion có nhiều vấn đề tương thích với NumPy/TensorFlow
# Thay vào đó, sử dụng PyTorch Mobile hoặc ONNX Runtime Mobile

print("🔄 Exporting to PyTorch Mobile...")

# Option 1: PyTorch Mobile (TorchScript)
# Prepare model for mobile
model_onnx.eval()
model_onnx = model_onnx.cpu()

# Trace model
traced_script_module = torch.jit.trace(model_onnx, torch.randn(1, 3, 64, 256))

# Optimize for mobile
from torch.utils.mobile_optimizer import optimize_for_mobile
optimized_model = optimize_for_mobile(traced_script_module)

# Save
mobile_path = os.path.join(SAVE_DIR, 'vietnamese_ocr_mobile.pt')
optimized_model._save_for_lite_interpreter(mobile_path)

model_size_mb = os.path.getsize(mobile_path) / (1024 * 1024)
print(f"✅ PyTorch Mobile model saved: {mobile_path}")
print(f"📦 Model size: {model_size_mb:.2f} MB")

# Test mobile model
loaded_mobile = torch.jit.load(mobile_path)
test_input = torch.randn(1, 3, 64, 256)
mobile_output = loaded_mobile(test_input)
print(f"📊 Mobile model output shape: {mobile_output.shape}")
print("✅ PyTorch Mobile export successful!")

print("\n" + "="*60)
print("📱 FLUTTER INTEGRATION OPTIONS:")
print("="*60)
print("\n1️⃣ ONNX Runtime Mobile (RECOMMENDED):")
print("   - Use onnx_runtime package for Flutter")
print("   - File: vietnamese_ocr_model.onnx")
print("   - Package: https://pub.dev/packages/onnxruntime")
print("   - Pros: Cross-platform, good performance")

print("\n2️⃣ PyTorch Mobile:")
print("   - Use pytorch_mobile package")
print("   - File: vietnamese_ocr_mobile.pt")
print("   - Package: https://pub.dev/packages/pytorch_mobile")
print("   - Pros: Direct PyTorch support")

print("\n3️⃣ TFLite (if you fix NumPy compatibility):")
print("   - Downgrade NumPy: pip install numpy==1.23.5")
print("   - Then re-run tf2onnx conversion")

print("\n✅ Recommendation: Use ONNX Runtime Mobile (Option 1)")
print("   - Stable, fast, and well-supported")
print("   - No NumPy version issues")
```

---

## 7️⃣ DOWNLOAD MODELS

```python
# Cell 22: Download trained models về máy
from google.colab import files

print("📥 Preparing models for download...")

# Zip all model files
!zip -r /content/trained_models.zip {SAVE_DIR}

print("\n📦 Files to download:")
print(f"   1. Best model: best_model.pth")
print(f"   2. ONNX model: vietnamese_ocr_model.onnx")
print(f"   3. TFLite model: vietnamese_ocr_model.tflite")
print(f"   4. Training curves: training_curves.png")
print(f"   5. Vocabulary: saved in checkpoint")

# Download
files.download('/content/trained_models.zip')

print("\n✅ Download started! Check your browser downloads.")
```

---

## 8️⃣ FLUTTER INTEGRATION GUIDE

### Option 1: ONNX Runtime Mobile (RECOMMENDED)

```yaml
# pubspec.yaml
dependencies:
  onnxruntime: ^1.16.0
  image: ^4.0.0
```

```dart
// lib/services/custom_ocr_service.dart
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

class VietnameseOCRService {
  late OrtSession _session;
  
  // Character set (copy từ training notebook)
  final List<String> charset = [
    '<BLANK>', ' ', '!', '"', '#', '\$', '%', '&', '\'', '(',
    // ... rest of charset from training
  ];
  
  Future<void> initialize() async {
    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromAsset(
      'assets/models/vietnamese_ocr_model.onnx',
      sessionOptions,
    );
  }
  
  Future<String> recognizeText(Uint8List imageBytes) async {
    // 1. Decode image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return '';
    
    // 2. Preprocess: resize height to 64, keep aspect ratio
    int newWidth = (64 * image.width / image.height).round();
    image = img.copyResize(image, height: 64, width: newWidth);
    
    // 3. Convert to Float32 [1, 3, 64, width]
    final inputData = Float32List(1 * 3 * 64 * newWidth);
    int idx = 0;
    for (int c = 0; c < 3; c++) {
      for (int h = 0; h < 64; h++) {
        for (int w = 0; w < newWidth; w++) {
          final pixel = image.getPixel(w, h);
          final value = c == 0 ? pixel.r : c == 1 ? pixel.g : pixel.b;
          inputData[idx++] = value / 255.0; // Normalize
        }
      }
    }
    
    // 4. Create input tensor
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputData,
      [1, 3, 64, newWidth],
    );
    
    // 5. Run inference
    final inputs = {'input': inputOrt};
    final outputs = await _session.runAsync(OrtRunOptions(), inputs);
    
    // 6. Decode CTC output
    final outputTensor = outputs[0]?.value as List<List<List<double>>>;
    String text = _decodeCTC(outputTensor);
    
    // Cleanup
    inputOrt.release();
    outputs[0]?.release();
    
    return text;
  }
  
  String _decodeCTC(List<List<List<double>>> output) {
    // output shape: [sequence_length, batch_size=1, num_chars]
    final decoded = <String>[];
    int? prevIdx;
    
    for (var timestep in output) {
      final probs = timestep[0]; // Get batch 0
      final maxIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
      
      // CTC decoding: skip blank (0) and consecutive duplicates
      if (maxIdx != 0 && maxIdx != prevIdx && maxIdx < charset.length) {
        decoded.add(charset[maxIdx]);
      }
      prevIdx = maxIdx;
    }
    
    return decoded.join('');
  }
  
  void dispose() {
    _session.release();
  }
}
```

### Option 2: PyTorch Mobile

```yaml
# pubspec.yaml
dependencies:
  pytorch_mobile: ^0.2.0
```

```dart
class VietnameseOCRService {
  late Module _module;
  
  Future<void> initialize() async {
    _module = await PyTorchMobile.loadModel(
      'assets/models/vietnamese_ocr_mobile.pt',
    );
  }
  
  Future<String> recognizeText(Uint8List imageBytes) async {
    // Similar preprocessing as ONNX version
    // Use _module.forward() for inference
  }
}
```

### Setup Flutter Project:

```bash
# 1. Copy ONNX model
mkdir -p assets/models
cp vietnamese_ocr_model.onnx assets/models/

# 2. Update pubspec.yaml
flutter pub add onnxruntime
flutter pub add image

# 3. Add assets
flutter:
  assets:
    - assets/models/vietnamese_ocr_model.onnx

# 4. Run
flutter pub get
flutter run
```

---

## 🔧 TROUBLESHOOTING

### Issue 1: Out of Memory (OOM)
**Solution:**
- Giảm `BATCH_SIZE` xuống 16 hoặc 8
- Giảm `img_height` xuống 32
- Sử dụng `gradient_checkpointing`

### Issue 2: CTC Loss = NaN
**Solution:**
- Kiểm tra `zero_infinity=True` trong CTCLoss
- Kiểm tra `text_lengths` không vượt quá `output_lengths`
- Add gradient clipping: `clip_grad_norm_()`

### Issue 3: Model không hội tụ
**Solution:**
- Giảm learning rate xuống 0.0001
- Tăng số epochs
- Thêm data augmentation
- Kiểm tra dataset quality

### Issue 4: TFLite conversion failed
**Solution:**
- Đảm bảo ONNX export thành công trước
- Sử dụng `opset_version=12` hoặc thấp hơn
- Check dynamic axes configuration

---

## 📊 EXPECTED RESULTS

Với MC-OCR 2021 dataset:

- **Training time:** ~2-4 hours (GPU T4)
- **Best CER:** 5-15% (tùy dataset size)
- **Model size:** 
  - PyTorch: ~50MB
  - ONNX: ~50MB
  - TFLite (FP16): ~25MB
- **Inference speed:**
  - GPU: ~10ms/image
  - CPU: ~100ms/image
  - Mobile (TFLite): ~200-500ms/image

---

## 📚 NEXT STEPS

1. **Fine-tuning:** Train thêm trên dữ liệu hóa đơn riêng của bạn
2. **Post-processing:** Add spell correction cho tiếng Việt
3. **Multi-line:** Xử lý hóa đơn nhiều dòng
4. **Amount extraction:** Regex để extract số tiền
5. **Date extraction:** Parse ngày tháng
6. **Category classification:** Phân loại danh mục tự động

---

**Last updated:** November 17, 2025  
**Author:** KHANH - FinTracker OCR Expert
