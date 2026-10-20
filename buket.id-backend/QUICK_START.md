# Quick Start Buket.id

Backend aktif memakai Node.js + Express dan PostgreSQL. Flutter tetap menjadi frontend.

## Backend

```powershell
cd D:\web\buketttt\buket.id-backend
npm install
npm start
```

API: `http://localhost:8080`; health check: `http://localhost:8080/health`.

Pastikan service PostgreSQL aktif dan nilai `DB_*`, `JWT_SECRET`, serta `GOOGLE_CLIENT_ID` (OAuth Web Client ID dari Google Cloud) tersedia di `.env`. Untuk schema database baru, ikuti `POSTGRES_SETUP.md`.

Tambahkan origin web aplikasi ke **Authorized JavaScript origins** pada OAuth Web Client, misalnya `http://localhost:5173` untuk development. Client ID yang sama dipasang pada `web/index.html` Flutter dan `GOOGLE_CLIENT_ID` backend. Android juga memerlukan OAuth Android Client yang cocok dengan application ID dan SHA-1 signing certificate.

## Flutter

Di terminal lain:

```powershell
cd D:\web\buketttt\buket.id
flutter run -d web-server --web-port 5173
```

Buka `http://localhost:5173`.
