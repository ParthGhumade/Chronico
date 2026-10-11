#!/bin/bash
set -e

echo "=== Starting Chronico Container ==="

MODE="${1:-all}"
if [ "$RUN_ALL" = "true" ]; then
    MODE="all"
fi

if [ "$MODE" = "bot" ]; then
    echo "Starting Chronico Telegram Bot polling service..."
    exec python -m backend.run_bot
elif [ "$MODE" = "api" ]; then
    echo "Starting Chronico FastAPI Application on port ${PORT:-8000}..."
    exec uvicorn backend.main:app --host 0.0.0.0 --port "${PORT:-8000}"
elif [ "$MODE" = "all" ]; then
    echo "Starting both FastAPI Server (port ${PORT:-8000}) and Telegram Bot in single container..."
    uvicorn backend.main:app --host 0.0.0.0 --port "${PORT:-8000}" &
    API_PID=$!
    
    python -m backend.run_bot &
    BOT_PID=$!
    
    trap "kill -TERM $API_PID $BOT_PID 2>/dev/null || true" SIGINT SIGTERM
    wait -n
    exit $?
else
    # Fallback to passing custom commands
    exec "$@"
fi

