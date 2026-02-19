#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Stopping Crash2Cost Services${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

check_port() {
    lsof -ti:$1 > /dev/null 2>&1
    return $?
}

stop_by_port() {
    local port=$1
    local name=$2
    local pattern=$3
    local pids=""

    if [ -n "$port" ] && check_port "$port"; then
        pids=$(lsof -ti:"$port" 2>/dev/null)
    fi

    if [ -z "$pids" ] && [ -n "$pattern" ]; then
        pids=$(pgrep -f "$pattern" 2>/dev/null)
    fi

    if [ -z "$pids" ]; then
        echo -e "${YELLOW}• $name is not running${NC}"
        return 0
    fi

    echo -e "${BLUE}Stopping $name...${NC}"
    kill $pids 2>/dev/null

    local waited=0
    while [ $waited -lt 10 ]; do
        sleep 1
        if [ -n "$port" ] && ! check_port "$port"; then
            break
        fi
        if [ -z "$port" ] && [ -n "$pattern" ] && ! pgrep -f "$pattern" > /dev/null 2>&1; then
            break
        fi
        waited=$((waited + 1))
    done

    local still_running=0
    if [ -n "$port" ] && check_port "$port"; then
        still_running=1
    fi
    if [ -n "$pattern" ] && pgrep -f "$pattern" > /dev/null 2>&1; then
        still_running=1
    fi

    if [ $still_running -eq 1 ]; then
        echo -e "${YELLOW}   Forcing $name to stop...${NC}"
        [ -n "$pattern" ] && pkill -9 -f "$pattern" 2>/dev/null
        [ -n "$port" ] && kill -9 $pids 2>/dev/null
    fi

    if [ -n "$port" ] && check_port "$port"; then
        echo -e "${YELLOW}   $name may still be running on port $port${NC}"
    elif [ -n "$pattern" ] && pgrep -f "$pattern" > /dev/null 2>&1; then
        echo -e "${YELLOW}   $name may still be running${NC}"
    else
        echo -e "${GREEN}   $name stopped${NC}"
    fi
}

echo -e "${YELLOW}Stopping backend services...${NC}"
stop_by_port 8002 "Auth Service" "AuthServiceApplication"
stop_by_port 8080 "API Gateway" "ApiGatewayApplication"
stop_by_port 8003 "Report Service" "ReportServiceApplication"
stop_by_port 8004 "ML Service" "server.py"
echo ""

echo -e "${YELLOW}Stopping frontend...${NC}"
if check_port 5173; then
    stop_by_port 5173 "Frontend (Vite)" ""
elif check_port 5174; then
    stop_by_port 5174 "Frontend (Vite)" ""
else
    echo -e "${YELLOW}• Frontend (Vite) is not running${NC}"
fi
echo ""

verify_port() {
    local port=$1
    local name=$2

    if check_port "$port"; then
        echo -e "${YELLOW}   $name still bound to port $port${NC}"
        return 1
    fi
    echo -e "${GREEN}   $name port $port is free${NC}"
    return 0
}

echo -e "${YELLOW}Verifying ports are freed...${NC}"
verify_port 8002 "Auth Service"
verify_port 8080 "API Gateway"
verify_port 8003 "Report Service"
verify_port 8004 "ML Service"
verify_port 5173 "Frontend"
verify_port 5174 "Frontend (alt)"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All services stopped (where possible)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
    echo -e "${YELLOW}Stopping MongoDB...${NC}"
    BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd "$BASE_DIR/../docker"
    if [ -f "docker-compose.yml" ]; then
        docker-compose down 2>/dev/null || docker compose down 2>/dev/null
        echo -e "${GREEN}   MongoDB stopped${NC}"
    fi
else
    echo -e "${YELLOW}Note:${NC} MongoDB is still running."
    echo -e "${YELLOW}To stop MongoDB too:${NC} ./stop-all.sh --all"
fi
