# STRUKTUR PROYEK BUKET.ID

## 📁 Folder Structure

```
buket/
├── lib/
│   ├── models/
│   │   ├── user.dart              # Model pengguna
│   │   ├── bouquet.dart           # Model buket bunga
│   │   ├── cart_item.dart         # Model item keranjang
│   │   ├── order.dart             # Model pesanan
│   │   ├── city.dart              # Model kota
│   │   └── index.dart             # Export models
│   │
│   ├── screens/
│   │   ├── login_screen.dart      # Halaman login
│   │   ├── register_screen.dart   # Halaman registrasi
│   │   ├── home_screen.dart       # Halaman utama/menu
│   │   ├── product_detail_screen.dart  # Detail produk
│   │   ├── payment_screen.dart    # Halaman pembayaran
│   │   └── index.dart             # Export screens
│   │
│   ├── services/
│   │   ├── auth_service.dart      # Service autentikasi
│   │   ├── city_service.dart      # Service kota (Jabodetabek)
│   │   ├── bouquet_service.dart   # Service produk buket
│   │   ├── cart_service.dart      # Service keranjang
│   │   └── index.dart             # Export services
│   │
│   ├── widgets/                    # (Ready untuk reusable widgets)
│   │
│   └── main.dart                   # Entry point aplikasi
│
├── assets/
│   ├── images/                     # Gambar produk (placeholder)
│   ├── icons/                      # Icon custom
│   └── data/                       # Data statis
│
├── .vscode/
│   ├── launch.json                # VS Code debug config
│   └── settings.json              # VS Code settings
│
├── pubspec.yaml                    # Dependencies & config
├── analysis_options.yaml           # Lint rules
├── .gitignore                      # Git ignore rules
├── README.md                       # Dokumentasi lengkap
├── PANDUAN.md                      # Panduan pengguna Indonesia
└── QUICKSTART.md                   # Quick start guide
```

## 📊 Data Models

### User
```dart
class User {
  String id;
  String name;
  String email;
  String phone;
  String city;
  String? address;
}
```

### Bouquet (Produk)
```dart
class Bouquet {
  String id;
  String name;
  String description;
  double price;
  String city;
  List<String> images;
  String category;      // Budget/Standard/Premium/Luxury
  double rating;        // 0-5
  int reviews;
}
```

### CartItem
```dart
class CartItem {
  String id;
  Bouquet bouquet;
  int quantity;
  double get total => bouquet.price * quantity;
}
```

### Order
```dart
class Order {
  String id;
  String userId;
  List<CartItem> items;
  double totalPrice;
  String status;
  DateTime createdAt;
  String paymentMethod;
  String address;
}
```

### City
```dart
class City {
  String id;
  String name;
  String province;
}
```

## 🔧 Services (Business Logic)

### AuthService
- `login()` - Login dengan email, password, dan kota
- `register()` - Registrasi akun baru
- `getCurrentUser()` - Ambil data pengguna saat ini
- `isLoggedIn()` - Cek status login
- `logout()` - Logout pengguna
- `updateUserCity()` - Update kota pengguna
- `getUserCity()` - Ambil kota pengguna

### CityService
- `getCities()` - Ambil semua kota (10 kota Jabodetabek)
- `getCityById()` - Cari kota berdasarkan ID
- `getCityByName()` - Cari kota berdasarkan nama

**Kota yang Tersedia:**
- Jakarta Pusat, Selatan, Timur, Barat, Utara
- Bogor, Depok
- Tangerang, Tangerang Selatan
- Bekasi

### BouquetService
- `getBouquetsByCity()` - Ambil produk berdasarkan kota
- `getBouquetById()` - Ambil produk berdasarkan ID
- `searchBouquets()` - Cari produk berdasarkan nama/deskripsi
- `filterByCategory()` - Filter produk berdasarkan kategori

**Total: 14 produk per kota x 10 kota = 140 produk**

### CartService
- `addItem()` - Tambah item ke keranjang
- `removeItem()` - Hapus item dari keranjang
- `updateQuantity()` - Update jumlah item
- `clearCart()` - Kosongkan keranjang
- `getTotalPrice()` - Hitung total harga
- `getItemCount()` - Hitung jumlah item

## 🎨 Screens (UI)

### 1. Login Screen
**Route**: `/login` (default)
- Input Email
- Input Password (dengan visibility toggle)
- Dropdown pilih Kota (10 kota)
- Tombol Login
- Link ke Register

**Fitur:**
- Form validation
- Loading state
- Error handling
- Auto navigate ke Home setelah berhasil

### 2. Register Screen
**Route**: `/register`
- Input Nama Lengkap
- Input Email
- Input Nomor Telepon
- Dropdown Kota
- Input Password
- Input Konfirmasi Password
- Tombol Daftar
- Link ke Login

**Fitur:**
- Full validation
- Password confirmation check
- Loading state
- Auto navigate ke Home setelah berhasil

### 3. Home Screen
**Route**: `/home`
- Header greeting dengan nama + kota
- Filter kategori (5 pilihan: Semua, Budget, Standard, Premium, Luxury)
- Grid produk (2 kolom)
- Setiap card menampilkan:
  - Icon placeholder
  - Nama produk
  - Rating & jumlah review
  - Harga dengan format Rp

**Fitur:**
- Real-time filter
- Tap product → ke detail
- Logout button
- Shopping cart button
- Session check

### 4. Product Detail Screen
**Route**: Dari Home screen (push)
- Gambar produk (icon placeholder)
- Nama produk
- Rating & review count
- Harga
- Badge kategori
- Deskripsi lengkap
- Quantity selector (+/-)
- Total price calculator
- Tombol "Lanjut ke Pembayaran"

**Fitur:**
- Dynamic price calculation
- Min quantity = 1
- Unlimited max quantity
- Back button

### 5. Payment Screen
**Route**: Dari Product Detail screen (push)
- Ringkasan pesanan (produk, qty, harga)
- Subtotal + Biaya Pengiriman (Rp 25,000)
- Total harga
- Input alamat pengiriman (textarea)
- Pilihan metode pembayaran (4 opsi):
  - Kartu Kredit
  - Transfer Bank
  - E-Wallet (GCash, OVO, Dana)
  - Cicilan 0%
- Tombol "Bayar Sekarang"

**Fitur:**
- Form validation
- Success dialog dengan detail order
- Auto navigate ke Home setelah berhasil

## 🎯 User Flow

```
Startup
   ↓
Login Screen
   ├─→ Login → Home Screen
   └─→ Register → Register Screen → Home Screen
         ↓
    Home Screen
   ├─→ Filter kategori
   ├─→ Tap produk → Product Detail Screen
   │              ↓
   │        Adjust quantity
   │              ↓
   │        Lanjut Pembayaran → Payment Screen
   │                           ↓
   │                     Isi alamat
   │                     Pilih metode pembayaran
   │                            ↓
   │                      Success → Back to Home
   │
   └─→ Logout → Login Screen
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2      # iOS icons
  provider: ^6.0.0             # State management (ready)
  intl: ^0.19.0                # Formatting
  google_fonts: ^6.0.0         # Custom fonts
  flutter_svg: ^2.0.0          # SVG support
  shared_preferences: ^2.2.0   # Local storage
  http: ^1.1.0                 # API calls (ready)
  image_picker: ^1.0.0         # Image selection (ready)
  cached_network_image: ^3.3.0 # Image caching (ready)
```

## 🎨 Design System

### Colors
- **Primary**: Colors.pink[400]
- **Background**: Colors.white
- **Text**: Colors.grey[800] / Colors.grey[600]
- **Accent**: Colors.pink[50] / Colors.pink[100]

### Typography
- **Font Family**: Poppins (configured in pubspec.yaml)
- **Heading**: Bold, 24-32px
- **Body**: Regular, 14-16px
- **Caption**: Regular, 12px

### Spacing
- **Padding**: 16px, 20px, 24px (std)
- **Margin**: 8px, 12px, 16px (std)
- **Border Radius**: 12px (std)

## 🔐 Authentication

**Current**: Dummy authentication dengan SharedPreferences
- Token disimpan di local storage
- User data disimpan terpisah
- Persist across app restarts

**For Production**: Perlu backend API dengan:
- JWT tokens
- Secure storage
- Password hashing
- Session management

## 💳 Payment

**Current**: Dummy payment processing
- No real payment
- Instant success confirmation
- Delivery fee: Rp 25,000 (fixed)

**For Production**: Integrasikan:
- Midtrans / Stripe / PayPal
- Real payment verification
- Webhook handling
- Receipt generation

## 📊 Product Data

**Total Produk**: 140 (14 per kota)

**Kategori:**
- Budget: Rp 120K - 180K
- Standard: Rp 190K - 280K
- Premium: Rp 230K - 320K
- Luxury: Rp 450K+

**Struktur Produk Tiap Kota:**
- 2 Budget items
- 2 Standard items
- 2 Premium items
- 1 Luxury item

## 🚀 Ready for Production Checklist

- [x] UI/UX Design (Material Design 3)
- [x] Authentication system
- [x] Product listing with filtering
- [x] Product detail view
- [x] Checkout flow
- [x] Payment form
- [ ] Backend API integration
- [ ] Real payment gateway
- [ ] Push notifications
- [ ] Order tracking
- [ ] User profile management
- [ ] Wishlist feature
- [ ] Review & rating system
- [ ] Live chat support

## 📱 Tested On

- Android 10+ (emulator)
- iOS 13+ (compatible)
- Web (Flutter for Web ready)

## 🐛 Known Limitations

1. Images are placeholders (icons)
2. Payment is simulated
3. No real backend API
4. Local authentication only
5. No push notifications
6. No order history persistence

## 📝 Notes

- Semua text dapat di-localize ke bahasa lain
- Color scheme dapat dengan mudah diubah di main.dart
- Struktur memudahkan penambahan features baru
- Error handling sudah implemented
- Form validation lengkap

---

**Version**: 1.0.0  
**Created**: November 2025  
**Flutter**: 3.0+  
**Dart**: 3.0+
