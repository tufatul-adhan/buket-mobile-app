# 🎀 Buket.id Logo & Branding Guide

## Struktur Logo

Logo Buket.id telah dibuat dengan tema buket bunga yang elegan dan modern. Logo dirancang dengan:
- **Warna Utama**: Pink #E91E63 (sesuai tema aplikasi)
- **Elemen**: Buket bunga dengan 5 bloom (merah pink, pink, dan light pink) dengan tangkai hijau
- **Gaya**: Simple, scalable, dan mudah dikenali

### File Logo

```
assets/icons/bouquet_logo.svg  ← Logo SVG source (scalable vector)
```

## Implementasi di Aplikasi

### 1. **Splash Screen** (✅ SUDAH SELESAI)
Logo bouquet ditampilkan dengan animasi loading 3 detik saat app startup.

```
lib/screens/splash_screen.dart
```

**Fitur:**
- Logo dalam circular white container (150x150px)
- Gradient pink background
- App name: "Buket.id"
- Tagline: "Buket Bunga Terbaik untuk Momen Spesialmu"
- Loading indicator dengan color white

**Navigasi:**
- Splash → Login (after 3 seconds)

### 2. **Launcher Icon** (Manual Setup Diperlukan)

Untuk mengganti default Flutter icon dengan custom logo bouquet:

#### **Option A: Menggunakan Flutter Launcher Icons Package (Recommended)**

1. Update `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

2. Buat file `flutter_launcher_icons.yaml` di root project:
```yaml
flutter_icons:
  ios: true
  android: true
  image_path: "assets/icons/bouquet_logo.svg"
  
  # Untuk Android
  adaptive_icon_background: "#FFE91E63"  # Pink
  adaptive_icon_foreground: "assets/icons/bouquet_logo.svg"
```

3. Generate icons:
```bash
flutter pub run flutter_launcher_icons
```

#### **Option B: Manual PNG Generation (untuk control lebih)**

1. Install `cairosvg` (Python):
```bash
pip install cairosvg
```

2. Jalankan script generator:
```bash
python generate_icons.py
```

3. Generated files:
```
android/app/src/main/res/mipmap-mdpi/ic_launcher.png (48x48)
android/app/src/main/res/mipmap-hdpi/ic_launcher.png (72x72)
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png (96x96)
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png (144x144)
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png (192x192)
```

#### **Option C: Online SVG to Icon Converter**

Jika tidak punya ImageMagick atau cairosvg:

1. Kunjungi: https://convertio.co/svg-png/ atau https://image.online-convert.com/
2. Upload: `assets/icons/bouquet_logo.svg`
3. Convert ke PNG dengan ukuran:
   - 48x48 (mdpi)
   - 72x72 (hdpi)
   - 96x96 (xhdpi)
   - 144x144 (xxhdpi)
   - 192x192 (xxxhdpi)
4. Copy file PNG ke folder yang sesuai di `android/app/src/main/res/mipmap-*/`

## Logo Variants

### SVG Format
- **File**: `assets/icons/bouquet_logo.svg`
- **Keuntungan**: Scalable, vector, file size kecil
- **Penggunaan**: Splash screen (via flutter_svg)

### PNG Format (Generated)
- **Ukuran**: 5 varian untuk berbagai device densities
- **Keuntungan**: Supported by native Android, rendering cepat
- **Penggunaan**: Launcher icon, notification icon

## Aturan Design

### Warna Palet
- **Primary Pink**: #E91E63
- **Light Pink**: #F48FB1
- **Very Light Pink**: #F8BBD0
- **Green (Stem)**: #4CAF50, #2E7D32, #388E3C
- **Gold (Center)**: #F06292

### Ukuran Minimum
- Splash screen: 150x150px (dalam container)
- App icon: 48px minimum (mdpi)
- Touch target: 48px recommended

### Padding
- Splash screen: 20px padding around logo
- App icon: No padding (fill entire canvas)

## Troubleshooting

### Icon tidak muncul setelah build
1. Run `flutter clean`
2. Run `flutter pub get`
3. Rebuild: `flutter run`

### Splash screen tidak muncul
1. Verify `splash_screen.dart` imported di `main.dart`
2. Verify routes di `MyApp` home property
3. Check `assets/icons/bouquet_logo.svg` exists

### SVG rendering error
1. Verify `flutter_svg: ^2.0.0` ada di pubspec.yaml
2. Run `flutter pub get`
3. Asset path harus exact: `assets/icons/bouquet_logo.svg`

## Next Steps

1. ✅ **Logo Design**: SVG bouquet logo created
2. ✅ **Splash Screen**: Implemented dengan logo
3. ⏳ **Launcher Icon**: Generate PNG variants (pilih Option A/B/C di atas)
4. ⏳ **Notification Icon**: Optional - dapat menggunakan icon yang sudah ada

## Files Modified

```
✅ assets/icons/bouquet_logo.svg         ← BARU: SVG logo
✅ lib/screens/splash_screen.dart        ← BARU: Splash screen dengan logo
✅ lib/screens/index.dart                ← UPDATED: Export splash screen
✅ lib/main.dart                         ← UPDATED: Set SplashScreen sebagai home
✅ generate_icons.py                     ← BARU: Script untuk generate PNG icons
✅ LOGO_BRANDING.md                      ← File ini: Dokumentasi
```

---

**Status**: Splash screen fully implemented ✅  
**Pending**: Generate & deploy launcher icons (pilih salah satu option di atas)
