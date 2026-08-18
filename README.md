# SmartOps Time Attendance

SmartOps is a portfolio-scale employee attendance system combining a Flutter client, a Spring Boot REST API, PostgreSQL, and a FastAPI face-verification service. It covers employee administration, JWT authentication, eKYC enrollment, kiosk attendance, leave/overtime workflows, shift management, and Excel reports.

> This is an academic project. Face liveness checks are heuristic and must not be treated as high-assurance biometric security.

## Key Features

- Role-based JWT authentication for administrators and employees
- Employee, department, and shift management
- QR and face-assisted kiosk check-in/check-out
- Leave, overtime, and shift-change workflows
- eKYC enrollment and administrator review
- Attendance dashboard and Excel export
- Consistent API envelopes, request validation, and centralized error handling
- Spring integration/controller tests with an isolated H2 test database

## Tech Stack

| Area | Technology |
| --- | --- |
| Client | Flutter, Dart, Dio/HTTP |
| Core API | Java 17, Spring Boot 3, Spring Security, Spring Data JPA |
| AI service | Python, FastAPI, DeepFace, OpenCV, MediaPipe |
| Database | PostgreSQL; H2 for automated tests |
| Testing | JUnit 5, Mockito, MockMvc, pytest |

## Architecture

```text
Flutter client
      |
      v
Spring REST controllers -> Services -> JPA repositories -> PostgreSQL
                              |
                              v
                       FastAPI AI service
```

The Core API owns business data and authorization. The AI service is an internal compute service; it does not access the database. This repository uses two deployable backend processes, not a large distributed microservice platform.

## Main Data Model

- `User` belongs to a `Department` and may have an assigned `ShiftConfig`.
- `FaceData` has a one-to-one relationship with `User`.
- `AttendanceLog`, `LeaveRequest`, `OvertimeRequest`, and `ShiftChangeRequest` belong to a user.
- Unique constraints protect usernames, employee codes, emails, department names, and shift names.

## Project Structure

```text
Backend/core_api/             Spring Boot REST API (primary backend)
Backend/ai_service/           FastAPI face processing service
Frontend/smartops_app/        Primary Flutter client
Documents/                    Academic requirements, designs, and reports
docs/                         Portfolio audit and interview notes
SourceCode/Frontend/          Earlier coursework snapshot; not the primary client
untitled4/                    Face-detection prototype; not required for normal setup
```

## Getting Started

### Prerequisites

- JDK 17
- Python 3.11 or 3.12
- Flutter SDK compatible with Dart `^3.11.3`
- PostgreSQL 14+

### 1. Configure PostgreSQL

Create an empty database named `smartops_db`. Copy `.env.example` to `.env` for reference, then export the required values in your shell. Spring Boot reads operating-system environment variables; it does not automatically load `.env`.

Required values:

```text
DB_PASSWORD=<your local PostgreSQL password>
JWT_SECRET=<random secret of at least 32 characters>
```

Optional demo users can be created with `DEMO_DATA_ENABLED=true`. Their local demo password is `123456`; never enable demo data in a public deployment.

### 2. Run the AI service

```powershell
cd Backend/ai_service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python main.py
```

The AI service listens on `http://localhost:8080`. The first model initialization can take time and download model assets.

### 3. Run the Core API

```powershell
$env:DB_PASSWORD = "your-local-password"
$env:JWT_SECRET = "replace-with-a-random-secret-at-least-32-characters"
cd Backend/core_api
.\mvnw.cmd spring-boot:run
```

The Core API listens on `http://localhost:9090`; health check: `GET /health`.

### 4. Run Flutter

The client API base URL is currently defined in `Frontend/smartops_app/lib/core/constants.dart`. Set it for the device/emulator being used, then run:

```powershell
cd Frontend/smartops_app
flutter pub get
flutter run --dart-define=KIOSK_API_KEY=your-local-kiosk-key
```

## Main API Groups

| Path | Purpose | Access |
| --- | --- | --- |
| `POST /api/v1/auth/login` | Issue JWT | Public |
| `/api/v1/employee/**` | Attendance history and employee requests | Employee/Admin |
| `/api/v1/admin/**` | Administration, review, reports | Admin |
| `/api/v1/kiosk/**` | Kiosk verification flow | `X-Kiosk-Key` device credential |
| `GET /health` | Health check | Public |

All normal JSON responses use `status`, `message`, `data`, and `timestamp` fields.

## Testing

Core tests are self-contained and use H2:

```powershell
cd Backend/core_api
.\mvnw.cmd test
```

AI tests require the Python dependencies (including model/runtime libraries):

```powershell
cd Backend/ai_service
python -m pytest -q
```

Flutter checks:

```powershell
cd Frontend/smartops_app
flutter analyze
flutter test
```

## Security Notes

- Passwords created by the application are BCrypt-hashed.
- Secrets and database credentials are supplied through environment variables.
- Kiosk routes require a separately rotatable `KIOSK_API_KEY`; this credential grants no admin role.
- Attendance writes lock the employee row inside a transaction so concurrent scans cannot create duplicate daily records.
- Java-to-AI calls use explicit connection and response timeouts; attendance is written only after verification succeeds.
- Admin report exports require the `ADMIN` role.
- CORS origins are configured using `CORS_ALLOWED_ORIGINS`.
- Rotate any credential that existed in repository history before using the project outside a local environment.

## Biometric Data Considerations

Face embeddings are sensitive data. The API does not log full embeddings or raw uploads, and the AI service itself keeps request images in memory only for request processing. The current enrollment flow stores uploaded eKYC files under the configured upload path, so retention/deletion automation and encryption at rest remain mandatory work before a real deployment. Production should also restrict and audit access and obtain appropriate consent. This project does not claim regulatory compliance.

Legacy databases may still contain plaintext passwords from earlier revisions. Follow [the migration runbook](docs/LEGACY_PASSWORD_MIGRATION.md); the application does not provide a plaintext authentication fallback.

## Screenshots

UI mockups are available under [`Documents/GUI design`](Documents/GUI%20design/). Add real screenshots to `docs/screenshots/` before publishing: login, employee dashboard, attendance, kiosk/face verification, leave management, admin dashboard, and reporting. No fabricated screenshots are included.

## Future Improvements

- Replace Hibernate schema updates with versioned Flyway migrations.
- Authenticate kiosk devices independently from employee JWTs.
- Store biometric templates encrypted and define retention/deletion policies.
- Containerize all services after the local workflow is stable.
- Consolidate or archive the historical frontend snapshots in a separate cleanup change.

## Author

Academic portfolio project. Add your name and contact links before publishing.
