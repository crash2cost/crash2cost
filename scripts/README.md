# Crash2Cost Service Scripts

These scripts help you manage all Crash2Cost services easily.

## Available Scripts

###  Start All Services
```bash
./scripts/start-all.sh
```
Starts all services in the correct order:
- **Starts MongoDB** automatically via Docker if not running
- Loads environment variables from `.env` files
- Starts Auth Service (port 8002)
- Starts API Gateway (port 8080)
- Starts Report Service (port 8003)
- Starts ML Service (port 8004)
- Starts Frontend (port 5173 or 5174)
- Makes Maven wrappers executable automatically
- Checks for npm dependencies and installs if needed

###  Stop All Services
```bash
./scripts/stop-all.sh          # Stop services only (keep MongoDB running)
./scripts/stop-all.sh --all    # Stop everything including MongoDB
```
Gracefully stops all running services:
- Stops all Spring Boot services
- Stops ML Service
- Stops Vite development server
- Verifies ports are freed
- Use `--all` flag to also stop MongoDB

###  Check Service Status
```bash
./scripts/status.sh
```
Shows the current status of all services:
- Checks MongoDB status
- Checks which services are running
- Shows process IDs (PIDs)
- Displays service URLs
- Overall health summary

###  Clean Logs
```bash
./scripts/clean-logs.sh
```
Removes all log files:
- Cleans logs for all services
- Cleans MongoDB logs

## Service Ports

| Service         | Port  | URL                        |
|----------------|-------|----------------------------|
| MongoDB        | 27017 | mongodb://localhost:27017  |
| Auth Service   | 8002  | http://localhost:8002      |
| API Gateway    | 8080  | http://localhost:8080      |
| Report Service | 8003  | http://localhost:8003      |
| Frontend       | 5173* | http://localhost:5173      |

*Frontend may use port 5174 if 5173 is already in use

## Troubleshooting

### Services won't start
1. Check if ports are in use: `./scripts/status.sh`
2. Stop all services: `./scripts/stop-all.sh`
3. Try starting again: `./scripts/start-all.sh`

### Auth Service fails
- Make sure `.env` file exists in `backend/auth-service/`
- Required variables: `JWT_SECRET`, `JWT_EXPIRATION`

### Frontend doesn't load
- Check `frontend/frontend.log` for errors
- Make sure npm dependencies are installed
- Try: `cd frontend && npm install`

### View Logs
All logs are stored in the `logs/` directory:

```bash
# Auth Service
tail -f logs/auth-service/auth-service.log

# API Gateway
tail -f logs/api-gateway/api-gateway.log

# Report Service
tail -f logs/report-service/report-service.log

# Frontend
tail -f logs/frontend/frontend.log
```

## Quick Start Workflow

1. **Start MongoDB**:
   ```bash
   cd docker && docker-compose up -d
   ```

2. **Start All Services**:
   ```bash
   ./scripts/start-all.sh
   ```

3. **Check Status**:
   ```bash
   ./scripts/status.sh
   ```

4. **Open the App**:
   Visit http://localhost:5173 (or the port shown in status)

5. **When Done**:
   ```bash
   ./scripts/stop-all.sh
   ```

## Environment Setup

The start script will automatically:
-  Make Maven wrapper scripts executable
-  Load environment variables from .env files
-  Check and install frontend dependencies
-  Handle port conflicts (frontend)
-  Wait for services to start

## Test Credentials

After first run, you can create a test user:
- Username: `testuser`
- Password: `TestPass123!`
- Email: `test@example.com`
