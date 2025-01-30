#!/bin/bash

echo "Updating Crypto Trading Bot project..."

# 1. Update `app/routes.py` with the new functionality
cat <<EOF > app/routes.py
from flask import Flask, render_template, request, redirect, url_for, jsonify
from flask_socketio import SocketIO, emit
import threading
import time
from dotenv import load_dotenv
import os
import random

# Load environment variables
load_dotenv()

# Initialize Flask and Flask-SocketIO
app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'your_secret_key')
socketio = SocketIO(app)

# Global variable for mock portfolio value
portfolio_value = 10000

# Mock function to simulate trading bot (replace with actual bot logic)
def trading_bot():
    global portfolio_value
    while True:
        time.sleep(10)  # Simulate periodic updates every 10 seconds
        # Simulate portfolio value change
        portfolio_value += random.uniform(-50, 50)
        # Emit updated portfolio value to the frontend
        socketio.emit('update', {'portfolio_value': portfolio_value})

# Start trading bot in a background thread
threading.Thread(target=trading_bot, daemon=True).start()

# Route: Homepage/Dashboard
@app.route('/')
def dashboard():
    return render_template('dashboard.html')

# Route: Login Page
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # Implement authentication logic here
        username = request.form['username']
        password = request.form['password']
        if username == "admin" and password == "password":  # Replace with secure logic
            return redirect(url_for('dashboard'))
        return "Login failed!"
    return render_template('login.html')

# Route: Configuration Page
@app.route('/config', methods=['GET', 'POST'])
def config():
    if request.method == 'POST':
        # Save configuration settings (e.g., API keys, trading parameters)
        api_key = request.form['api_key']
        secret_key = request.form['secret_key']
        # Save to environment variables or a secure database
        os.environ['BINANCE_API_KEY'] = api_key
        os.environ['BINANCE_SECRET_KEY'] = secret_key
        return "Configuration saved!"
    return render_template('config.html')

# Route: API Endpoint to get portfolio value (optional for debugging)
@app.route('/api/portfolio', methods=['GET'])
def get_portfolio_value():
    return jsonify({'portfolio_value': portfolio_value})

# SocketIO: Real-time updates
@socketio.on('connect')
def handle_connect():
    print("Client connected!")
    emit('update', {'portfolio_value': portfolio_value})

@socketio.on('disconnect')
def handle_disconnect():
    print("Client disconnected!")

# Main entry point
if __name__ == '__main__':
    socketio.run(app, debug=True)
EOF

echo "Updated app/routes.py."

# 2. Create HTML templates for dashboard, login, and config pages
mkdir -p app/templates

# Dashboard Template
cat <<EOF > app/templates/dashboard.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crypto Trading Bot Dashboard</title>
    <script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
</head>
<body>
    <h1>Crypto Trading Bot Dashboard</h1>
    <p>Portfolio Value: $<span id="portfolio-value">10000</span></p>

    <script>
        const socket = io();
        socket.on('update', function(data) {
            document.getElementById('portfolio-value').innerText = data.portfolio_value.toFixed(2);
        });
    </script>
</body>
</html>
EOF

echo "Created app/templates/dashboard.html."

# Login Template
cat <<EOF > app/templates/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
</head>
<body>
    <h1>Login</h1>
    <form method="POST">
        <label for="username">Username:</label>
        <input type="text" id="username" name="username" required>
        <br>
        <label for="password">Password:</label>
        <input type="password" id="password" name="password" required>
        <br>
        <button type="submit">Login</button>
    </form>
</body>
</html>
EOF

echo "Created app/templates/login.html."

# Configuration Template
cat <<EOF > app/templates/config.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configuration</title>
</head>
<body>
    <h1>Configuration</h1>
    <form method="POST">
        <label for="api_key">API Key:</label>
        <input type="text" id="api_key" name="api_key" required>
        <br>
        <label for="secret_key">Secret Key:</label>
        <input type="password" id="secret_key" name="secret_key" required>
        <br>
        <button type="submit">Save Configuration</button>
    </form>
</body>
</html>
EOF

echo "Created app/templates/config.html."

# 3. Ensure Flask-SocketIO is installed
echo "Ensuring Flask-SocketIO is installed..."
pip install flask-socketio

# 4. Provide instructions for running the updated app
echo "All changes applied successfully! To run the updated app:"
echo "1. Activate your virtual environment:"
echo "   source venv/bin/activate"
echo "2. Start the Flask app:"
echo "   python app/routes.py"
echo "3. Open your browser and visit:"
echo "   Dashboard: http://127.0.0.1:5000/"
echo "   Login: http://127.0.0.1:5000/login"
echo "   Configuration: http://127.0.0.1:5000/config"