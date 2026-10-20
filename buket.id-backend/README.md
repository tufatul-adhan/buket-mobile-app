# Buket.id API

Backend aplikasi ini memakai **Node.js + Express** dengan PostgreSQL. Flutter tetap menjadi aplikasi frontend. React adalah library antarmuka dan tidak menjalankan server API sendiri.

## Menjalankan backend

```powershell
cd D:\web\buketttt\buket.id-backend
npm install
npm start
```

Pastikan `.env` berisi konfigurasi PostgreSQL (`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`), `JWT_SECRET`, `GOOGLE_CLIENT_ID` (OAuth Web Client ID), dan `PORT`. Server API berjalan di `http://localhost:8080`; cek koneksi database di `http://localhost:8080/health`.

Mode pengembangan dengan restart otomatis:

```powershell
npm run dev
```

## Database

Skema PostgreSQL ada di `migrations/schema.sql`. Panduan setup database ada di `POSTGRES_SETUP.md`.

## Endpoint

| Method | Endpoint | Akses |
| --- | --- | --- |
| `GET` | `/health` | Publik |
| `POST` | `/api/auth/register` | Publik |
| `POST` | `/api/auth/login` | Publik |
| `POST` | `/api/auth/google` | Publik; menerima Google ID token terverifikasi |
| `GET`, `PUT` | `/api/profile` | Login |
| `GET` | `/api/products`, `/api/products/search`, `/api/products/:id` | Login |
| `GET`, `POST`, `PUT`, `DELETE` | `/api/cart` dan `/api/cart/:id` | Login |
| `GET`, `POST` | `/api/orders` | Login |
| `GET` | `/api/orders/:id` | Pemilik order |
| `POST`, `PUT`, `DELETE` | `/api/seller/products` dan `/api/seller/products/:id` | Seller/Admin |
| `GET`, `PUT` | `/api/seller/orders` dan `/api/seller/orders/:id` | Seller/Admin |
| `GET` | `/api/admin/stats` | Admin |

Endpoint terlindungi menerima `Authorization: Bearer <token>`.

Server API ada di `src/server.js`; `npm start` menjalankan file tersebut.
