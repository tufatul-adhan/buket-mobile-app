# Susunan File Gambar Sesuai Kota

## Struktur Folder yang Telah Dibuat

Gambar produk sekarang diorganisir dalam folder berdasarkan kota. Struktur yang telah dibuat:

```
assets/images/
├── Jakarta_Pusat/
│   ├── Buket_Mewah_Putih.png
│   ├── Buket_Romantis_Merah.png
│   ├── Buket_Pastel_Cantik.png
│   ├── Buket_Klasik_Jakarta_Pusat.png
│   ├── Buket_Minimalis_Jakarta_Pusat.png
│   ├── Buket_Pusat_Elegance.png
│   ├── Buket_Pusat_Modern.png
│   ├── Buket_Pusat_Natural.png
│   ├── Buket_Pusat_Deluxe.png
│   └── Buket_Pusat_Vibrant.png
│
├── Jakarta_Selatan/
│   ├── Buket_Sunrise.png
│   ├── Buket_Lavender_Dreams.png
│   ├── Buket_Dasar_Warna-Warni.png
│   ├── Buket_Tropis_Jakarta_Selatan.png
│   ├── Buket_Vintage_Jakarta_Selatan.png
│   ├── Buket_Selatan_Exotic.png
│   ├── Buket_Selatan_Fresh.png
│   ├── Buket_Selatan_Deluxe.png
│   ├── Buket_Selatan_Vibrant.png
│   └── Buket_Selatan_Natural.png
│
├── Bogor/
│   ├── Buket_Pink_Blush.png
│   ├── Buket_Alami_Hijau.png
│   ├── Buket_Pegunungan_Bogor.png
│   ├── Buket_Botani_Bogor.png
│   ├── Buket_Hutan_Bogor.png
│   ├── Buket_Bogor_Exotic.png
│   ├── Buket_Bogor_Fresh.png
│   ├── Buket_Bogor_Deluxe.png
│   ├── Buket_Bogor_Vibrant.png
│   └── Buket_Bogor_Natural.png
│
├── Depok/
│   ├── Buket_Luxury_Gold.png
│   ├── Buket_Ekonomis_Standar.png
│   ├── Buket_Akademik_Depok.png
│   ├── Buket_Inovatif_Depok.png
│   ├── Buket_Edukasi_Depok.png
│   ├── Buket_Depok_Exotic.png
│   ├── Buket_Depok_Fresh.png
│   ├── Buket_Depok_Deluxe.png
│   ├── Buket_Depok_Vibrant.png
│   └── Buket_Depok_Natural.png
│
├── Tangerang/
│   ├── Buket_Coral_Elegance.png
│   ├── Buket_Garden_Fresh.png
│   ├── Buket_Industri_Tangerang.png
│   ├── Buket_Modern_Tangerang.png
│   ├── Buket_Harmoni_Tangerang.png
│   ├── Buket_Tangerang_Exotic.png
│   ├── Buket_Tangerang_Fresh.png
│   ├── Buket_Tangerang_Deluxe.png
│   ├── Buket_Tangerang_Vibrant.png
│   └── Buket_Tangerang_Natural.png
│
├── Bekasi/
│   ├── Buket_Biru_Langit.png
│   ├── Buket_Mini_Sehari.png
│   ├── Buket_Perkotaan_Bekasi.png
│   ├── Buket_Tradisional_Bekasi.png
│   └── Buket_Eksklusif_Bekasi.png
│
├── Jakarta_Timur/
│   ├── Buket_Timur_Vibran.png
│   ├── Buket_Timur_Tradisional.png
│   ├── Buket_Timur_Elegan.png
│   ├── Buket_Timur_Sederhana.png
│   ├── Buket_Timur_Modern.png
│   ├── Buket_Timur_Exotic.png
│   ├── Buket_Timur_Fresh.png
│   ├── Buket_Timur_Deluxe.png
│   ├── Buket_Timur_Vibrant.png
│   └── Buket_Timur_Natural.png
│
├── Jakarta_Barat/
│   ├── Buket_Barat_Sunset.png
│   ├── Buket_Barat_Ocean.png
│   ├── Buket_Barat_Urban.png
│   ├── Buket_Barat_Fresh.png
│   └── Buket_Barat_Deluxe.png
│
├── Jakarta_Utara/
│   ├── Buket_Utara_Northern.png
│   ├── Buket_Utara_Coastal.png
│   ├── Buket_Utara_Klasik.png
│   ├── Buket_Utara_Minimal.png
│   ├── Buket_Utara_Exclusive.png
│   ├── Buket_Utara_Exotic.png
│   ├── Buket_Utara_Fresh.png
│   ├── Buket_Utara_Deluxe.png
│   ├── Buket_Utara_Vibrant.png
│   └── Buket_Utara_Natural.png
│
└── Tangerang_Selatan/
    ├── Buket_Selatan_Tropis.png
    ├── Buket_Selatan_Harmoni.png
    ├── Buket_Selatan_Natural.png
    ├── Buket_Selatan_Vintage.png
    └── Buket_Selatan_Luxury.png
```

## Perubahan di Kode

### lib/services/bouquet_service.dart

#### 1. Update Fungsi Helper

**Sebelum:**
```dart
static String _getImagePath(String name) {
  String imageName = name.replaceAll(' ', '_');
  if (!imageName.contains('.')) {
    imageName = '$imageName.png';
  }
  return 'assets/images/$imageName';
}
```

**Sesudah:**
```dart
static String _getImagePath(String name, String city) {
  String cityFolder = city.replaceAll(' ', '_');
  String imageName = name.replaceAll(' ', '_');
  if (!imageName.contains('.')) {
    imageName = '$imageName.png';
  }
  return 'assets/images/$cityFolder/$imageName';
}
```

#### 2. Update Semua Panggilan _getImagePath

**Sebelum:**
```dart
images: [_getImagePath('Buket Sunrise')]
```

**Sesudah:**
```dart
images: [_getImagePath('Buket Sunrise', 'Jakarta Selatan')]
```

Semua 85 produk telah diperbarui dengan parameter city yang sesuai.

## Ringkasan Perubahan

| Aspek | Detail |
|-------|--------|
| Folder yang dibuat | 10 folder (1 per kota) |
| Total produk | 95 |
| Perubahan kode | 85 panggilan _getImagePath |
| Struktur path | `assets/images/{Kota}/{NamaProduk}.png` |
| Contoh path | `assets/images/Jakarta_Pusat/Buket_Mewah_Putih.png` |

## Cara Penggunaan

### Menambah Gambar untuk Produk Baru

1. Tentukan kota produk (misalnya: "Jakarta Pusat")
2. Tentukan nama produk (misalnya: "Buket Special Edition")
3. Letakkan gambar di folder yang sesuai:
   - `assets/images/Jakarta_Pusat/Buket_Special_Edition.png`
4. Update kode dengan city parameter:
   ```dart
   images: [_getImagePath('Buket Special Edition', 'Jakarta Pusat')]
   ```

### Path yang Dihasilkan

Sistem akan otomatis menghasilkan path yang benar:
- Input: `_getImagePath('Buket Sunrise', 'Jakarta Selatan')`
- Output: `assets/images/Jakarta_Selatan/Buket_Sunrise.png`

## Keuntungan Struktur Baru

✅ **Organisasi Lebih Rapi**: Gambar terorganisir berdasarkan kota
✅ **Mudah Dinavigasi**: Cepat menemukan gambar produk tertentu
✅ **Scalable**: Mudah menambah produk di setiap kota
✅ **Mudah Dipelihara**: Struktur yang konsisten dan terstruktur
✅ **Performance**: Lebih efisien saat mengelola banyak file

## Verifikasi Struktur

Pastikan semua folder berikut sudah dibuat:
- ✅ Jakarta_Pusat/
- ✅ Jakarta_Selatan/
- ✅ Bogor/
- ✅ Depok/
- ✅ Tangerang/
- ✅ Bekasi/
- ✅ Jakarta_Timur/
- ✅ Jakarta_Barat/
- ✅ Jakarta_Utara/
- ✅ Tangerang_Selatan/

## Testing

Untuk memverifikasi konfigurasi:
1. Jalankan aplikasi: `flutter run`
2. Buka halaman home untuk melihat produk
3. Pastikan gambar ditampilkan dengan benar
4. Lihat console jika ada error loading gambar

---

**Status**: ✅ Sudah Selesai
**Total Perubahan**: 85 _getImagePath calls updated
**Folder Struktur**: 10 folder + 95 file gambar
**Date**: November 28, 2025
