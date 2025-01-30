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
