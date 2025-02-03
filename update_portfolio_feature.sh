#!/bin/bash

# Define the app directory
APP_DIR="crypto_trading_bot"

# Ensure the required database table exists
echo "Creating portfolio table in SQLite database..."
sqlite3 "$APP_DIR/data/trade_logs.db" <<EOF
CREATE TABLE IF NOT EXISTS portfolio (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    value REAL NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Add utility functions for portfolio value in utils.py
UTILS_FILE="$APP_DIR/app/utils.py"
echo "Adding utility functions to manage portfolio value in $UTILS_FILE..."
cat <<EOF >> $UTILS_FILE

import sqlite3
from datetime import datetime

DB_PATH = 'data/trade_logs.db'

def save_portfolio_value(value):
    """Save the current portfolio value to the database."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM portfolio")  # Ensure only the latest value is stored
    cursor.execute("INSERT INTO portfolio (value, updated_at) VALUES (?, ?)", (value, datetime.now()))
    conn.commit()
    conn.close()

def get_portfolio_value():
    """Retrieve the portfolio value from the database."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT value FROM portfolio ORDER BY updated_at DESC LIMIT 1")
    row = cursor.fetchone()
    conn.close()
    if row:
        return row[0]
    return 0.0  # Default value if no portfolio value exists
EOF

# Modify trading_bot.py to save and retrieve portfolio value
TRADING_BOT_FILE="$APP_DIR/app/trading_bot.py"
echo "Modifying $TRADING_BOT_FILE to handle portfolio value..."
sed -i '/import os/a from app.utils import get_portfolio_value, save_portfolio_value' $TRADING_BOT_FILE
sed -i '/# Trading bot initialization/a portfolio_value = get_portfolio_value()\nprint(f"Starting with portfolio value: {portfolio_value}")' $TRADING_BOT_FILE
sed -i '/# Update portfolio value/a save_portfolio_value(portfolio_value)\nprint(f"Portfolio value updated: {portfolio_value}")' $TRADING_BOT_FILE

# Update routes.py to pass portfolio value to dashboard
ROUTES_FILE="$APP_DIR/app/routes.py"
echo "Updating $ROUTES_FILE to include portfolio value in the dashboard..."
sed -i '/from flask import/a from app.utils import get_portfolio_value' $ROUTES_FILE
sed -i '/def dashboard():/a \    portfolio_value = get_portfolio_value()' $ROUTES_FILE
sed -i '/render_template/a \        portfolio_value=portfolio_value,' $ROUTES_FILE

# Add graceful shutdown handling in run.py
RUN_FILE="$APP_DIR/run.py"
echo "Adding graceful shutdown handling to $RUN_FILE..."
sed -i '/import sys/a from app.utils import save_portfolio_value' $RUN_FILE
sed -i '/def main()/a def handle_shutdown_signal(signal, frame):\n    global portfolio_value\n    print("Saving portfolio value before shutdown...")\n    save_portfolio_value(portfolio_value)\n    sys.exit(0)\n' $RUN_FILE
sed -i '/signal.signal/a signal.signal(signal.SIGINT, handle_shutdown_signal)' $RUN_FILE

# Confirmation message
echo "Portfolio value storage and retrieval functionality successfully added to the app!"
echo "Restart your app and test the changes."