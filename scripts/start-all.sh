#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Starting Crash2Cost Services${NC}"
echo -e "${BLUE}========================================${NC}"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

check_port() {
    lsof -ti:$1 > /dev/null 2>&1
    return $?
}

wait_for_service() {
    local port=$1
    local service=$2
    local max_attempts=30
    local attempt=0
    
    echo -e "${YELLOW}Waiting for $service to start on port $port...${NC}"
    while [ $attempt -lt $max_attempts ]; do
        if check_port $port; then
            echo -e "${GREEN} $service is ready!${NC}"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    echo -e "${YELLOW} $service may not have started${NC}"
    return 1
}

echo -e "${YELLOW}Stopping existing services...${NC}"
pkill -f "AuthServiceApplication" 2>/dev/null
pkill -f "ApiGatewayApplication" 2>/dev/null
pkill -f "ReportServiceApplication" 2>/dev/null
pkill -f "server.py" 2>/dev/null
pkill -f "vite" 2>/dev/null
sleep 3

echo -e "${BLUE}Checking MongoDB...${NC}"
if ! check_port 27017; then
    echo -e "${YELLOW}Starting MongoDB via Docker...${NC}"
    cd "$BASE_DIR/../docker"
    if [ -f "docker-compose.yml" ]; then
        docker-compose up -d mongo 2>/dev/null || docker compose up -d mongo 2>/dev/null
        sleep 3
        if check_port 27017; then
            echo -e "${GREEN} MongoDB started on port 27017${NC}"
        else
            echo -e "${YELLOW} MongoDB may not have started. Check Docker.${NC}"
        fi
    else
        if command -v mongod &> /dev/null; then
            mongod --dbpath "$BASE_DIR/../docker/mongo-data" --fork --logpath "$BASE_DIR/../logs/mongodb.log" 2>/dev/null
            echo -e "${GREEN} MongoDB started locally${NC}"
        else
            echo -e "${YELLOW} MongoDB not found. Install Docker or MongoDB locally.${NC}"
        fi
    fi
else
    echo -e "${GREEN} MongoDB already running on port 27017${NC}"
fi

cd "$BASE_DIR/../backend/auth-service"
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
    echo -e "${GREEN}   Environment variables loaded${NC}"
else
    echo -e "${YELLOW}   No .env file found, using defaults${NC}"
    export JWT_SECRET="404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970"
    export JWT_EXPIRATION="3600000"
    export MONGO_CLIENT_CONNECTION="mongodb://localhost:27017/crash2cost"
fi

mkdir -p "$BASE_DIR/../logs/auth-service"
mkdir -p "$BASE_DIR/../logs/api-gateway"
mkdir -p "$BASE_DIR/../logs/report-service"
mkdir -p "$BASE_DIR/../logs/ml-service"
mkdir -p "$BASE_DIR/../logs/frontend"

echo -e "${BLUE}Starting Auth Service (port 8002)...${NC}"
cd "$BASE_DIR/../backend/auth-service"
chmod +x ./mvnw 2>/dev/null
nohup ./mvnw spring-boot:run > "$BASE_DIR/../logs/auth-service/auth-service.log" 2>&1 &
AUTH_PID=$!

echo -e "${BLUE}Starting API Gateway (port 8080)...${NC}"
cd "$BASE_DIR/../backend/api-gateway"
chmod +x ./mvnw 2>/dev/null
nohup ./mvnw spring-boot:run > "$BASE_DIR/../logs/api-gateway/api-gateway.log" 2>&1 &
GATEWAY_PID=$!

echo -e "${BLUE}Starting Report Service (port 8003)...${NC}"
cd "$BASE_DIR/../backend/report-service"
chmod +x ./mvnw 2>/dev/null
nohup ./mvnw spring-boot:run > "$BASE_DIR/../logs/report-service/report-service.log" 2>&1 &
REPORT_PID=$!

echo -e "${BLUE}Starting ML Service (port 8004)...${NC}"
ML_DIR="$BASE_DIR/../ml-service"
ML_PY="$ML_DIR/.venv/bin/python"
if [ ! -x "$ML_PY" ]; then
    ML_PY="python3"
fi
cd "$ML_DIR"
nohup "$ML_PY" server.py --port 8004 > "$BASE_DIR/../logs/ml-service/ml-service.log" 2>&1 &
ML_PID=$!

wait_for_service 8002 "Auth Service"
wait_for_service 8080 "API Gateway"
wait_for_service 8003 "Report Service"
wait_for_service 8004 "ML Service"

echo -e "${BLUE}Starting Frontend...${NC}"
cd "$BASE_DIR/../frontend"

if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}  Installing frontend dependencies...${NC}"
    npm install
fi

nohup npm run dev > "$BASE_DIR/../logs/frontend/frontend.log" 2>&1 &
FRONTEND_PID=$!
sleep 3

FRONTEND_PORT=$(grep -o 'localhost:[0-9]*' "$BASE_DIR/../logs/frontend/frontend.log" 2>/dev/null | head -1 | cut -d':' -f2)
if [ -z "$FRONTEND_PORT" ]; then
    FRONTEND_PORT="5173"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All Services Started!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MongoDB:         http://localhost:27017${NC}"
echo -e "${GREEN}Auth Service:    http://localhost:8002${NC}"
echo -e "${GREEN}API Gateway:     http://localhost:8080${NC}"
echo -e "${GREEN}Report Service:  http://localhost:8003${NC}"
echo -e "${GREEN}ML Service:      http://localhost:8004${NC}"
echo -e "${GREEN}Frontend:        http://localhost:$FRONTEND_PORT${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Process IDs:${NC}"
echo -e "  Auth Service:   $AUTH_PID"
echo -e "  API Gateway:    $GATEWAY_PID"
echo -e "  Report Service: $REPORT_PID"
echo -e "  ML Service:     $ML_PID"
echo -e "  Frontend:       $FRONTEND_PID"
echo ""
echo -e "${YELLOW}To stop all services:${NC} cd scripts && ./stop-all.sh"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo -e "  Auth Service:   tail -f logs/auth-service/auth-service.log"
echo -e "  API Gateway:    tail -f logs/api-gateway/api-gateway.log"
echo -e "  Report Service: tail -f logs/report-service/report-service.log"
echo -e "  ML Service:     tail -f logs/ml-service/ml-service.log"
echo -e "  Frontend:       tail -f logs/frontend/frontend.log"
echo ""
echo -e "${GREEN} Open the app: http://localhost:$FRONTEND_PORT${NC}"
