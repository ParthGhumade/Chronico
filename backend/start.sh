#!/bin/bash
set -e

echo "=== Starting Chronico Container ==="

if [ "$1" = "bot" ]; then
    echo "Starting Chronico Telegram Bot polling service..."
    exec python -m backend.run_bot
elif [ "$1" = "api" ]; then
    echo "Starting Chronico FastAPI Application..."
    exec uvicorn backend.main:app --host 0.0.0.0 --port "${PORT:-8000}"
elif [ "$1" = "all" ] || [ "$RUN_ALL" = "true" ]; then
    echo "Starting both FastAPI Server and Telegram Bot in single container..."
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
