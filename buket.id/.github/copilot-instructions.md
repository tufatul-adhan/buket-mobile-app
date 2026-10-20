# Buket.id - AI Coding Agent Instructions

## Project Overview
**Buket.id** adalah aplikasi Flutter e-commerce untuk penjualan buket bunga dengan basis lokal. Aplikasi ini menghubungkan pembeli dengan penjual buket di berbagai kota di area Jakarta dan sekitarnya.

### Tech Stack
- **Framework**: Flutter (Dart 3.0+)
- **Storage**: SharedPreferences (local data persistence)
- **UI**: Material Design 3
- **Image Handling**: Image.asset() untuk lokal, CachedNetworkImage untuk network
- **State Management**: Stateful widgets (no Provider/Riverpod)

---

## Architecture & Components

### 1. **Service Layer** (`lib/services/`)
Services adalah singleton-like classes yang mengelola business logic:
- **AuthService**: Autentikasi user (login/register), menyimpan data ke SharedPreferences
- **BouquetService**: Katalog produk (95 items) dengan city filtering, image path generation
- **CartService**: Shopping cart management in-memory (tidak persistent, cleared on app restart)
- **CityService**: List kota yang tersedia untuk filter
- **Pattern**: Services biasanya instantiated di State widgets, passed ke child widgets yang membutuhkan

**Key Pattern - Service Instantiation**:
```dart
// Di State class
final _bouquetService = BouquetService();
final _cartService = CartService();
```

### 2. **Data Models** (`lib/models/`)
- **Bouquet**: Product dengan fields: id, name, description, price, city, images[], category, rating, reviews
- **CartItem**: item di keranjang dengan: id, bouquet, quantity, computed total
- **User**: authenticated user dengan: id, name, email, phone, city
- **City**: city metadata
- **Order**: order history (belum fully implemented)

### 3. **Screens/Routing** (`lib/screens/`)
All screens are StatefulWidget with State classes. Named routes registered di main.dart:
- **LoginScreen**: Email/password auth, city selection
- **RegisterScreen**: User registration
- **HomeScreen**: Product catalog dengan city-based filtering, search, category filter
- **ProductDetailScreen**: Product detail, quantity selector, dual actions (Add to Cart / Buy Now)
- **CartScreen**: Shopping cart management (add, remove, update qty, checkout)
- **PaymentScreen**: Checkout dan payment simulation

---

## Critical Patterns & Conventions

### Image Path Generation (City-Organized Structure)
**File**: `lib/services/bouquet_service.dart` - `_getImagePath()` method
- Gambar disimpan di: `assets/images/{CityFolder}/{ProductName}.png`
- City names di convert dengan `replaceAll(' ', '_')` → Jakarta Pusat = Jakarta_Pusat/
- **Important**: pubspec.yaml HARUS list semua city folders explicitly di assets section
- **Pattern**: 
```dart
static String _getImagePath(String name, String city) {
  String cityFolder = city.replaceAll(' ', '_');
  String imageName = name; // No replacement - keep spaces
  if (!imageName.contains('.')) imageName = '$imageName.png';
  return 'assets/images/$cityFolder/$imageName';
}
```

### Screen Navigation & Service Passing
Services dipass sebagai constructor parameters ke screens yang membutuhkannya:
```dart
// From HomeScreen to ProductDetailScreen
ProductDetailScreen(
  bouquet: bouquet,
  cartService: _cartService, // Cart service passed for Add to Cart
)
```

**Important**: CartService, AuthService, BouquetService TIDAK shared globally - setiap HomeScreen instance punya CartService-nya sendiri. Ini berarti cart tidak persistent.

### Dual Action Button Pattern
Detail screen punya 2 buttons:
1. **"Tambah Keranjang"** (gray) - calls `_addToCart()` → quantity item ditambah ke CartService
2. **"Beli Sekarang"** (pink) - calls `_buyNow()` → langsung ke PaymentScreen untuk checkout

### Image Display Abstraction
Method `_buildImage(String imagePath)` ada di multiple screens. Detects image type:
```dart
Widget _buildImage(String imagePath) {
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return CachedNetworkImage(...);
  } else {
    return Image.asset(...);
  }
}
```

### Language Localization
Aplikasi **100% dalam Bahasa Indonesia** - semua strings hardcoded. Method names, UI text, comments semua Indonesian.

---

## Common Workflows

### Adding New Product
1. Edit `bouquet_service.dart` - tambah Bouquet object ke `_bouquets` list
2. Gunakan `_getImagePath('Nama Produk', 'Nama Kota')` untuk images path
3. Untuk product baru, tambahkan file image ke `assets/images/{CityName}/`

### Adding New City
1. Buat folder di `assets/images/{CityName}/` (dengan underscore untuk spaces)
2. Update `pubspec.yaml` - tambah di assets section:
   ```yaml
   - assets/images/{CityName}/
   ```
3. Jalankan `flutter pub get` (untuk refresh asset registration)
4. Update CityService atau hardcode city list di filter sections

### Debugging Image Loading
- Check `pubspec.yaml` - city folder harus terdaftar di assets
- Verify file names exact match (case-sensitive)
- Look for errorBuilder output (Icon dengan `Icons.local_florist` means image not found)
- Use `_buildImage()` method untuk handle both network dan local gracefully

### Testing Cart Flow
1. HomeScreen klik produk → ProductDetailScreen
2. Atur quantity dengan +/- buttons
3. "Tambah Keranjang" → snackbar confirmation
4. Klik cart icon di header → CartScreen menampilkan items
5. "Beli Sekarang" → PaymentScreen
6. Atau dari CartScreen klik "Checkout" → PaymentScreen

---

## Build & Run Commands

```bash
# Standard Flutter commands
flutter clean          # Clean build artifacts
flutter pub get        # Resolve dependencies
flutter run            # Run di device/emulator (interactive device selection)
flutter run -d [id]    # Run di specific device

# No tests exist - project focuses on manual testing
```

---

## Important Gotchas & Notes

1. **CartService tidak persistent** - cart di-clear saat app restart. Design ini intentional.
2. **Hardcoded 95 products** - BouquetService bukan dari API, semua 95 produk hardcoded di service
3. **No Provider/Riverpod** - state management manual via setState, services passed as params
4. **SharedPreferences untuk Auth** - auth data stored lokal, no real API backend
5. **Images di pubspec.yaml harus explicit** - Flutter tidak auto-discover subfolder assets tanpa explicit listing
6. **All Dart strings in Indonesian** - variable names, method names, komentar semua Indonesian

---

## File Structure Reference

```
lib/
├── main.dart                    # App entry, routing setup
├── config/app_theme.dart        # Material theme (pink-based)
├── models/
│   ├── bouquet.dart             # Product model
│   ├── cart_item.dart           # Cart item model
│   ├── user.dart                # User auth model
│   └── city.dart, order.dart     # Other models
├── services/
│   ├── auth_service.dart        # Auth & SharedPrefs
│   ├── bouquet_service.dart     # Products (95 items), image path generation
│   ├── cart_service.dart        # In-memory cart
│   └── city_service.dart        # Cities
└── screens/
    ├── login_screen.dart        # Auth screen
    ├── home_screen.dart         # Catalog + cart access
    ├── product_detail_screen.dart # Detail + dual actions
    ├── cart_screen.dart         # Cart management
    └── payment_screen.dart      # Checkout

assets/images/
├── Jakarta_Pusat/               # 10 products
├── Jakarta_Selatan/             # 10 products
├── [8 other city folders]       # 5-10 products each
```

---

## Next Development Areas

- **Persistence**: CartService bisa dipindahkan ke SharedPreferences agar persistent
- **Real API**: Ganti hardcoded BouquetService dengan HTTP calls
- **Payment Integration**: PaymentScreen currently simulation-only
- **Order History**: Order model exists tapi belum fully implemented
- **Search Optimization**: Current search looping through all items
