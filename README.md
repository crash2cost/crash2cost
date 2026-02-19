# Crash2Cost

AI-powered vehicle damage assessment platform. Upload a photo of a damaged car and receive automated damage detection, severity classification, and repair cost estimation.

## Architecture

| Layer | Tech | Port |
|-------|------|------|
| Frontend | React + TypeScript + Vite | 5173 |
| API Gateway | Spring Cloud Gateway | 8080 |
| Auth Service | Spring Boot + MongoDB | 8002 |
| Report Service | Spring Boot + MongoDB | 8003 |
| ML Service | FastAPI + PyTorch | 8004 |
| Database | MongoDB (Docker) | 27017 |

## Project Structure

```
crash2cost/
├── frontend/                   # React + TypeScript + Vite
│   ├── src/
│   │   ├── api/                # Axios API integration layer
│   │   ├── components/         # Reusable UI components
│   │   │   ├── common/         # Button, Input, Select, Toast, ImageUpload
│   │   │   └── guard/          # Route protection (ProtectedRoute)
│   │   ├── pages/              # Feature-based page components
│   │   │   ├── dashboard/      # Main upload & assessment view
│   │   │   ├── history/        # Assessment history list
│   │   │   ├── login/          # User login
│   │   │   └── signup/         # User registration
│   │   ├── hooks/              # Custom React hooks (useAuth)
│   │   ├── types/              # TypeScript type definitions
│   │   ├── utils/              # Utility functions (JWT parsing)
│   │   └── constants/          # API endpoint constants
│   ├── package.json
│   └── vite.config.ts
│
├── backend/                    # Spring Boot microservices
│   ├── api-gateway/            # Routes requests to downstream services
│   ├── auth-service/           # JWT authentication & user management
│   │   ├── controller/         # REST endpoints
│   │   ├── service/            # Business logic
│   │   ├── repository/         # MongoDB data access
│   │   ├── model/              # Entity definitions
│   │   ├── dto/                # Data transfer objects
│   │   ├── security/           # JWT filter, utilities
│   │   ├── config/             # Spring & CORS configuration
│   │   └── exception/          # Global error handling
│   └── report-service/         # Report generation & ML integration
│       ├── controller/
│       ├── service/
│       ├── repository/
│       ├── model/
│       └── dto/
│
├── ml-service/                 # Python ML pipeline
│   ├── server.py               # FastAPI server entry point
│   ├── pipeline.py             # Orchestrates the 3-stage inference pipeline
│   ├── detection-model/        # YOLOv8 — detects damaged regions
│   ├── severity-model/         # ResNet — classifies damage severity (1-5)
│   ├── cost-model/             # Gradient Boosting — estimates repair cost (ILS)
│   ├── common/                 # Shared utilities & visualization
│   ├── config/                 # Damage type mappings
│   ├── tools/                  # Dataset preparation & labeling utilities
│   ├── tests/                  # Unit tests
│   └── requirements.txt
│
├── docker/                     # Docker Compose (MongoDB)
│   └── docker-compose.yml
│
├── scripts/                    # Service orchestration
│   ├── start-all.sh            # Start all services
│   ├── stop-all.sh             # Stop all services
│   ├── status.sh               # Health check
│   └── clean-logs.sh           # Remove log files
│
└── .github/                    # CI/CD workflows
```

## Quick Start

### Prerequisites

- Java 8+ & Maven
- Node.js 18+ & npm
- Python 3.10+ & pip
- Docker (for MongoDB)

### 1. Start MongoDB

```bash
cd docker && docker-compose up -d
```

### 2. Start all services

```bash
./scripts/start-all.sh
```

Or start individually:

```bash
# Backend services
cd backend/auth-service && mvn spring-boot:run
cd backend/api-gateway && mvn spring-boot:run
cd backend/report-service && mvn spring-boot:run

# ML service
cd ml-service && python server.py

# Frontend
cd frontend && npm install && npm run dev
```

### 3. Open the app

Navigate to [http://localhost:5173](http://localhost:5173)

## Environment Variables

Copy `.env.example` to `.env` in each service directory:

- `frontend/.env` — API base URL
- `backend/auth-service/.env` — JWT secret & expiration
- `backend/report-service/.env.example` — Service configuration

## ML Pipeline

The assessment pipeline runs three models in sequence:

1. **Detection** (YOLOv8) — Locates damaged regions with bounding boxes
2. **Severity** (ResNet) — Classifies each region's damage level (1-5)
3. **Cost** (Gradient Boosting) — Predicts repair cost based on part type, severity, and car segment
