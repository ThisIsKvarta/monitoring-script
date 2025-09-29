#!/bin/bash

PROCESS_NAME="test"
LOG_FILE="/var/log/monitoring.log"
API_URL="https://test.com/monitoring/test/api"
PID_FILE="/var/run/test_monitor.pid"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

mkdir -p $(dirname "$LOG_FILE")
touch "$LOG_FILE"
if [ ! -w "$LOG_FILE" ]; then
    logger -t monitoring_script "Error: No write permission for log file $LOG_FILE"
    exit 1
fi

CURRENT_PID=$(pgrep -f "$PROCESS_NAME" | head -n 1)
if [[ -n "$CURRENT_PID" ]]; then
    COMMAND_LINE=$(ps -o cmd= -p "$CURRENT_PID")
    if [[ "$COMMAND_LINE" == *"pgrep"* || "$COMMAND_LINE" == *"monitoring.sh"* ]]; then
        CURRENT_PID=""
    fi
fi

if [ -n "$CURRENT_PID" ]; then
    if [ -f "$PID_FILE" ]; then
        SAVED_PID=$(cat "$PID_FILE")
        if [ "$CURRENT_PID" != "$SAVED_PID" ]; then
            log_message "Процесс '$PROCESS_NAME' был перезапущен. Новый PID: $CURRENT_PID."
            echo "$CURRENT_PID" > "$PID_FILE"
        fi
    else
        log_message "Процесс '$PROCESS_NAME' запущен. PID: $CURRENT_PID."
        echo "$CURRENT_PID" > "$PID_FILE"
    fi

    curl -sS --fail --max-time 10 "$API_URL" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_message "Ошибка: Сервер мониторинга $API_URL недоступен."
    fi
else
    if [ -f "$PID_FILE" ]; then
        SAVED_PID=$(cat "$PID_FILE")
        if [ -n "$SAVED_PID" ]; then
            log_message "Процесс '$PROCESS_NAME' остановлен."
            echo "" > "$PID_FILE"
        fi
    fi
fi
