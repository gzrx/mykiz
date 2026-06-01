# MyKIZ Platform

A modular platform for **Kolej Ibu Zain (KIZ)** at Universiti Kebangsaan Malaysia (UKM), delivering a one-stop student living experience through three applications sharing a common backend.

## Overview

| Application | Technology | Description |
|-------------|-----------|-------------|
| **MyKIZ Backend** | Dart Frog (port 8080) | REST API serving both client apps |
| **MyKIZ Admin** | Flutter Web (port 3000) | Staff portal for managing announcements and complaints |
| **MyKIZ Siswa** | Flutter Mobile | Student app for viewing announcements and submitting complaints |

### MVP Features

- **Authentication** — JWT-based login with HMAC-SHA256, 24-hour token expiry
- **Role-Based Access Control** — Two roles: `student` and `admin`
- **Announcements** — CRUD with soft-delete (admin), read-only list/detail (student)
- **Complaints** — Submit with image upload (student), status advancement (admin)
- **Linear Status Machine** — `submitted` → `in_progress` → `resolved`

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Client Applications                    │
│  ┌──────────────────┐       ┌──────────────────────┐    │
│  │  MyKIZ Admin     │       │  MyKIZ Siswa         │    │
│  │  (Flutter Web)   │       │  (Flutter Mobile)    │    │
│  └────────┬─────────┘       └──────────┬───────────┘    │
└───────────┼─────────────────────────────┼───────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────────────────────────────────────┐
│                    Shared Packages                        │
│  ┌──────────────────┐       ┌──────────────────────┐    │
│  │  api_client       │──────▶│  shared_core         │    │
│  │  (dio HTTP)       │       │  (freezed models)    │    │
│  └────────┬─────────┘       └──────────────────────┘    │
└───────────┼─────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────┐
│              Backend — Dart Frog :8080                    │
│  ┌─────────┐  ┌──────────────┐  ┌─────────────────┐    │
│  │  Auth   │  │ Announcements│  │   Complaints    │    │
│  │ Service │  │   Service    │  │    Service      │    │
│  └────┬────┘  └──────┬───────┘  └───────┬─────────┘    │
└───────┼──────────────┼──────────────────┼───────────────┘
        │              │                  │
        ▼              ▼                  ▼
┌──────────────┐              ┌──────────────────┐
│  PostgreSQL  │              │      MinIO       │
│    :5432     │              │   :9000/:9001    │
└──────────────┘              └──────────────────┘
```

## Monorepo Structure

```
mykiz/
├── melos.yaml                 # Monorepo workspace configuration
├── docker-compose.yml         # PostgreSQL + MinIO infrastructure
├── .env.example               # Environment variable template
├── migrations/                # SQL schema migrations
│   ├── 001_create_users.sql
│   ├── 002_create_announcements.sql
│   └── 003_create_complaints.sql
└── packages/
    ├── backend/               # Dart Frog REST API
    ├── admin_web/             # Flutter Web (Admin)
    ├── student_app/           # Flutter Mobile (Student)
    ├── shared_core/           # Freezed models & enums
    └── api_client/            # Typed dio HTTP client
```

## Prerequisites

- [Dart SDK](https://dart.dev/get-dart) ≥ 3.0.0
- [Flutter](https://flutter.dev/docs/get-started/install) stable channel
- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Melos](https://melos.invertase.dev/) — `dart pub global activate melos`

## Getting Started

### 1. Clone and configure

```bash
git clone https://github.com/gzrx/mykiz.git
cd mykiz
cp .env.example .env
```

### 2. Start infrastructure

```bash
docker compose up -d
```

This starts PostgreSQL (port 5432) and MinIO (port 9000/9001). Migrations run automatically on first start.

### 3. Install dependencies

```bash
melos bootstrap
```

### 4. Generate code (Freezed models)

```bash
melos run build_runner
```

### 5. Seed the database

```bash
melos run seed
```

Creates test accounts:
| Role | Identifier | Password |
|------|-----------|----------|
| Student | A123456 | password123 |
| Student | A234567 | password123 |
| Student | A345678 | password123 |
| Admin | S98765 | password123 |
| Admin | S87654 | password123 |

### 6. Run the backend

```bash
cd packages/backend
dart_frog dev
```

Backend runs at `http://localhost:8080`.

### 7. Run the Admin Web app

```bash
cd packages/admin_web
flutter run -d chrome --web-port 3000
```

### 8. Run the Student App

```bash
cd packages/student_app
flutter run
```

## API Endpoints

All endpoints are versioned under `/api/v1/`.

| Method | Path | Auth | Role | Description |
|--------|------|:----:|------|-------------|
| POST | `/api/v1/auth/login` | ✗ | Any | Authenticate and receive JWT |
| GET | `/api/v1/announcements` | ✓ | Any | List announcements (paginated) |
| GET | `/api/v1/announcements/:id` | ✓ | Any | Get single announcement |
| POST | `/api/v1/announcements` | ✓ | Admin | Create announcement |
| PATCH | `/api/v1/announcements/:id` | ✓ | Admin | Update announcement |
| DELETE | `/api/v1/announcements/:id` | ✓ | Admin | Soft-delete announcement |
| GET | `/api/v1/complaints` | ✓ | Any | List complaints (role-scoped) |
| GET | `/api/v1/complaints/:id` | ✓ | Any | Get complaint (ownership check) |
| POST | `/api/v1/complaints` | ✓ | Student | Submit complaint |
| PATCH | `/api/v1/complaints/:id/status` | ✓ | Admin | Advance complaint status |
| GET | `/api/v1/images/:key` | ✓ | Any | Proxy image from MinIO |

### Response Format

**Success:**
```json
{
  "data": { ... },
  "meta": { "currentPage": 1, "limit": 20, "totalItems": 5, "totalPages": 1 }
}
```

**Error:**
```json
{
  "error": { "code": "VALIDATION_ERROR", "message": "Title must be between 1 and 200 characters." }
}
```

## Testing

The platform uses a dual testing approach: **property-based tests** (glados) for universal correctness properties and **unit tests** for specific examples.

```bash
# Run all tests across the monorepo
melos run test

# Run tests in a specific package
cd packages/backend && dart test
cd packages/shared_core && dart test
cd packages/api_client && dart test
cd packages/admin_web && flutter test
cd packages/student_app && flutter test
```

**Test coverage:** 250 tests across all packages covering 21 correctness properties.

## Melos Scripts

| Script | Command | Description |
|--------|---------|-------------|
| `test` | `melos run test` | Run tests in all packages |
| `analyze` | `melos run analyze` | Static analysis |
| `format` | `melos run format` | Format all Dart code |
| `build_runner` | `melos run build_runner` | Generate Freezed/JSON code |
| `seed` | `melos run seed` | Populate database with test data |

## Design System

The KIZ design system is shared across both Flutter apps:

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#C3DC52` (Lime Green) | Buttons, brand accent |
| Secondary | `#3B82F6` (Cobalt Blue) | Links, secondary actions |
| Navigation | `#759600` | AppBar background |
| Error | `#EF4444` | Error states |
| Typography | Poppins + League Spartan | Body + headings |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Dart Frog, PostgreSQL, MinIO, JWT (HMAC-SHA256), bcrypt |
| Shared | Freezed, json_serializable, dio |
| Frontend | Flutter, Riverpod, GoRouter, Google Fonts |
| Infrastructure | Docker Compose |
| Testing | glados (property-based), mocktail, dart test |
| Monorepo | Melos |

## License

This project is developed as a proof-of-concept for Kolej Ibu Zain, UKM.
