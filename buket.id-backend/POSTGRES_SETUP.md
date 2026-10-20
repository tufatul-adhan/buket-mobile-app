# Setup PostgreSQL

Backend Buket.id sekarang memakai PostgreSQL. Konfigurasi lokal di `.env` memakai database `buket_id` pada `localhost:5432` dan role `postgres`.

1. Pastikan service PostgreSQL aktif.
2. Jalankan PowerShell dari folder backend:

   ```powershell
   .\setup-postgres.ps1
   ```

   Skrip meminta password role PostgreSQL `postgres`, membuat database jika belum ada, lalu menerapkan `migrations/schema.sql`. Skrip aman dijalankan ulang.
3. Isi `DB_PASSWORD` di `.env` dengan password PostgreSQL yang sama. Jangan membagikan file `.env`.
4. Jalankan backend dengan `npm start` dari folder backend.

Jika `psql.exe` tidak berada di `D:\possql\bin`, berikan lokasinya:

```powershell
.\setup-postgres.ps1 -PsqlPath 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
```

Skema mencakup tabel users, sellers, products, orders, order_items, payments, cart_items, dan reviews. Akun admin bawaan dari schema lama tetap dibuat (`admin@buket.id`, password `admin123`); segera ganti password tersebut sebelum pemakaian nyata.
