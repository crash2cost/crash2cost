#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Crash2Cost Service Status${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

check_service() {
    local port=$1
    local service_name=$2
    local url=$3
    
    if lsof -ti:$port > /dev/null 2>&1; then
        PID=$(lsof -ti:$port)
        echo -e "${GREEN} $service_name${NC} (port $port) - PID: $PID"
        [ -n "$url" ] && echo -e "  URL: ${BLUE}$url${NC}"
        return 0
    else
        echo -e "${RED} $service_name${NC} (port $port) - Not running"
        return 1
    fi
}

echo -e "${YELLOW}Database:${NC}"
check_service 27017 "MongoDB" "mongodb://localhost:27017"
echo ""

echo -e "${YELLOW}Backend Services:${NC}"
check_service 8002 "Auth Service" "http://localhost:8002"
check_service 8080 "API Gateway" "http://localhost:8080"
check_service 8003 "Report Service" "http://localhost:8003"
check_service 8004 "ML Service" "http://localhost:8004"
echo ""

echo -e "${YELLOW}Frontend:${NC}"
if check_service 5173 "Frontend (Vite)" "http://localhost:5173"; then
    :
elif check_service 5174 "Frontend (Vite)" "http://localhost:5174"; then
    :
else
    :
fi
echo ""

SERVICES_UP=0
SERVICES_TOTAL=6

for port in 27017 8002 8080 8003 8004; do
    lsof -ti:$port > /dev/null 2>&1 && ((SERVICES_UP++))
done

(lsof -ti:5173 > /dev/null 2>&1 || lsof -ti:5174 > /dev/null 2>&1) && ((SERVICES_UP++))

echo -e "${BLUE}========================================${NC}"
if [ $SERVICES_UP -eq $SERVICES_TOTAL ]; then
    echo -e "${GREEN}  Status: All services running ($SERVICES_UP/$SERVICES_TOTAL)${NC}"
elif [ $SERVICES_UP -eq 0 ]; then
    echo -e "${RED}  Status: No services running${NC}"
else
    echo -e "${YELLOW}  Status: Partial ($SERVICES_UP/$SERVICES_TOTAL services running)${NC}"
fi
echo -e "${BLUE}========================================${NC}"
