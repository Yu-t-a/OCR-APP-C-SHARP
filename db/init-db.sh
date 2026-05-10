#!/bin/bash
# ============================================
# Database Initialization Script for MSSQL
# Runs SQL files in correct order
# ============================================
set -e

HOST="sqlserver"
USER="sa"
PASS="${MSSQL_SA_PASSWORD}"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
SCRIPTS_DIR="/scripts"

echo ">>> Waiting for SQL Server to be ready..."
RETRIES=30
until ${SQLCMD} -S ${HOST} -U ${USER} -P "${PASS}" -C -Q "SELECT 1" > /dev/null 2>&1; do
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES -le 0 ]; then
        echo "ERROR: SQL Server did not become ready in time."
        exit 1
    fi
    echo "    Not ready yet, retrying in 3s... ($RETRIES retries left)"
    sleep 3
done

echo ">>> SQL Server is ready!"

run_sql() {
    local file="$1"
    echo ">>> Running: $(basename $file)"
    ${SQLCMD} -S ${HOST} -U ${USER} -P "${PASS}" -C -i "${file}"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to run $(basename $file)"
        exit 1
    fi
    echo "    Done: $(basename $file)"
}

# Run in specific order (do NOT glob - avoid running init_auth_minimal.sql)
run_sql "${SCRIPTS_DIR}/init.sql"
run_sql "${SCRIPTS_DIR}/init_auth_api.sql"

# Seed test data only in development
if [ "${APP_ENV:-development}" = "development" ]; then
    echo ">>> Development mode: running seed data..."
    run_sql "${SCRIPTS_DIR}/seed_test_data.sql"
fi

echo ">>> Database initialization complete!"
