#!/bin/bash

# Step 1: Project Setup
echo "Setting up the project structure..."

# Create the main project folder
mkdir -p crypto_trading_bot
cd crypto_trading_bot

# Create subdirectories
mkdir -p app/templates app/static/css app/static/js tests data config

# Create Python files
touch app/__init__.py app/routes.py app/models.py app/trading_bot.py app/ml_model.py app/utils.py \
      config/__init__.py config/settings.py \
      tests/test_trading_bot.py tests/test_ml_model.py tests/test_utils.py \
      run.py README.md data/historical_data.csv

# Initialize trade_logs.db
sqlite3 data/trade_logs.db "VACUUM;"

# Step 2: Create virtual environment
echo "Creating a virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Step 3: Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install ccxt pandas pandas_ta scikit-learn xgboost flask flask-socketio flask-login python-dotenv plotly tailwindcss

# Save dependencies to requirements.txt
pip freeze > requirements.txt

# Step 4: Initialize Flask app
echo "Initializing Flask app..."
cat <<EOF > app/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crypto Trading Bot</title>
</head>
<body>
    <h1>Welcome to the Crypto Trading Bot Dashboard</h1>
</body>
</html>
EOF

cat <<EOF > app/routes.py
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)
EOF

# Step 5: Set up environment variables
echo "Setting up environment variables..."
cat <<EOF > .env
BINANCE_API_KEY=your_api_key
BINANCE_SECRET_KEY=your_secret_key
EOF

# Step 6: Display success message
echo "Project setup complete! To run the Flask app:"
echo "1. Activate the virtual environment: source venv/bin/activate"
echo "2. Run the app: python app/routes.py"
echo "3. Open a browser and go to http://127.0.0.1:5000"