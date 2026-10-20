# Buket.id

Buket.id is a bouquet shopping application with a Flutter client and a Node.js API backed by PostgreSQL.

## Project structure

- `buket.id/` — Flutter mobile and web application.
- `buket.id-backend/` — Express API, PostgreSQL setup, and database migrations.

## Requirements

- Flutter and Dart (see `buket.id/pubspec.yaml` for the SDK constraint).
- Node.js 20 or newer.
- PostgreSQL.

## Run the backend

1. Create `buket.id-backend/.env` using the variables documented in `buket.id-backend/QUICK_START.md`.
2. Install dependencies and start the API:

   ```powershell
   cd buket.id-backend
   npm ci
   npm run dev
   ```

The API listens on port `8080` by default. Its health endpoint is `http://localhost:8080/health`.

## Run the Flutter app

In another terminal:

```powershell
cd buket.id
flutter pub get
flutter run -d chrome
```

For non-local deployments, set `API_BASE_URL` with Flutter's `--dart-define` to the backend API base URL (including `/api`).

## Configuration

Keep credentials in local `.env` files. Do not commit database passwords, JWT secrets, or OAuth client secrets.
