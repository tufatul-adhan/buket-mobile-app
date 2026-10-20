# Referensi API Buket.id

Base URL: `http://localhost:8080/api`

Route selain health check memerlukan `Authorization: Bearer <token>` jika ditandai login.

## Health dan autentikasi

| Method | Path | Akses |
| --- | --- | --- |
| `GET` | `/health` | Publik; memastikan database terhubung |
| `POST` | `/auth/register` | Publik |
| `POST` | `/auth/login` | Publik |

Register menerima `email`, `username`, `password`, `phone`, `city`. Login menerima `email`, `password`. Keduanya mengembalikan token dan data user.

## User dan katalog

| Method | Path | Akses |
| --- | --- | --- |
| `GET`, `PUT` | `/profile` | Login |
| `GET` | `/products?city=...&category=...` | Login |
| `GET` | `/products/search?q=...` | Login |
| `GET` | `/products/:id` | Login |

## Keranjang dan pesanan

| Method | Path | Akses | Body utama |
| --- | --- | --- | --- |
| `GET`, `DELETE` | `/cart` | Login | — |
| `POST` | `/cart` | Login | `product_id`, `quantity` |
| `PUT`, `DELETE` | `/cart/:id` | Login | `quantity` untuk PUT |
| `GET` | `/orders` | Login | — |
| `GET` | `/orders/:id` | Pemilik order | — |
| `POST` | `/orders` | Login | `items: [{product_id, quantity}]` |

## Seller dan admin

| Method | Path | Akses |
| --- | --- | --- |
| `POST`, `PUT`, `DELETE` | `/seller/products` dan `/seller/products/:id` | Seller/Admin |
| `GET`, `PUT` | `/seller/orders` dan `/seller/orders/:id` | Seller/Admin |
| `GET` | `/admin/stats` | Admin |
