#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cleaning Crash2Cost Log Files${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGS_DIR="$BASE_DIR/../logs"

clean_service_logs() {
    local service_name=$1
    local log_dir="$LOGS_DIR/$service_name"

    if [ -d "$log_dir" ]; then
        local log_count=$(find "$log_dir" -name "*.log*" -type f 2>/dev/null | wc -l)
        if [ $log_count -gt 0 ]; then
            echo -e "${YELLOW}Cleaning $service_name logs...${NC}"
            find "$log_dir" -name "*.log*" -type f -delete 2>/dev/null
            echo -e "${GREEN}   Removed $log_count log file(s)${NC}"
        else
            echo -e "${GREEN}   $service_name - No logs to clean${NC}"
        fi
    else
        echo -e "${YELLOW}  • $service_name - No log directory${NC}"
    fi
}

clean_service_logs "auth-service"
clean_service_logs "api-gateway"
clean_service_logs "report-service"
clean_service_logs "ml-service"
clean_service_logs "frontend"

if [ -f "$LOGS_DIR/mongodb.log" ]; then
    echo -e "${YELLOW}Cleaning MongoDB logs...${NC}"
    rm -f "$LOGS_DIR/mongodb.log"
    echo -e "${GREEN}   Removed MongoDB log${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Log cleanup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} This only cleans logs in the logs/ directory."
echo -e "${YELLOW}To view current log sizes:${NC} du -sh logs/*"
