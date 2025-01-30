#!/bin/bash

# Description: This script updates the Flask project to implement JWT-based authentication, including login, password change functionality, and access control for protected routes, without overwriting existing code.

echo "Starting the update process for the Flask application..."

# Step 1: Install Required Libraries
pip install flask flask-bcrypt flask-jwt-extended flask-socketio python-dotenv sqlite3

if [ $? -ne 0 ]; then
  echo "Error installing dependencies. Please check your Python environment."
  exit 1
fi

echo "All required Python libraries have been installed successfully."

# Step 2: Create or Update Database Schema
if [ ! -f data/users.db ]; then
  echo "Creating the users database..."
  mkdir -p data
  sqlite3 data/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, password TEXT NOT NULL);"
  echo "Users database created successfully."
else
  echo "Users database already exists. Skipping creation."
fi

# Step 3: Add JWT Authentication to app/routes.py
cat <<'EOF' >> app/routes.py

# Additional Imports for JWT Authentication
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
import sqlite3

# Initialize JWT and Bcrypt
bcrypt = Bcrypt(app)
jwt = JWTManager(app)

# Route: Register
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({"msg": "Username and password are required."}), 400

    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

    try:
        conn = sqlite3.connect('data/users.db')
        cursor = conn.cursor()
        cursor.execute("INSERT INTO users (username, password) VALUES (?, ?)", (username, hashed_password))
        conn.commit()
        conn.close()
        return jsonify({"msg": "User registered successfully."}), 201
    except sqlite3.IntegrityError:
        return jsonify({"msg": "Username already exists."}), 400

# Route: Login
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    conn = sqlite3.connect('data/users.db')
    cursor = conn.cursor()
    cursor.execute("SELECT password FROM users WHERE username = ?", (username,))
    row = cursor.fetchone()
    conn.close()

    if row and bcrypt.check_password_hash(row[0], password):
        access_token = create_access_token(identity=username)
        return jsonify({"access_token": access_token}), 200
    return jsonify({"msg": "Invalid username or password."}), 401

# Route: Change Password
@app.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    current_user = get_jwt_identity()
    data = request.get_json()
    old_password = data.get('old_password')
    new_password = data.get('new_password')

    conn = sqlite3.connect('data/users.db')
    cursor = conn.cursor()
    cursor.execute("SELECT password FROM users WHERE username = ?", (current_user,))
    row = cursor.fetchone()

    if row and bcrypt.check_password_hash(row[0], old_password):
        hashed_new_password = bcrypt.generate_password_hash(new_password).decode('utf-8')
        cursor.execute("UPDATE users SET password = ? WHERE username = ?", (hashed_new_password, current_user))
        conn.commit()
        conn.close()
        return jsonify({"msg": "Password updated successfully."}), 200

    conn.close()
    return jsonify({"msg": "Old password is incorrect."}), 400

# Protected route example
@app.route('/dashboard', methods=['GET'])
@jwt_required()
def dashboard():
    current_user = get_jwt_identity()
    return jsonify({"msg": f"Welcome {current_user} to your dashboard."}), 200
EOF

if [ $? -ne 0 ]; then
  echo "Error updating app/routes.py."
  exit 1
fi

echo "JWT authentication routes have been added to app/routes.py."

# Step 4: Instructions for Running the App
cat <<INSTRUCTIONS

Update process completed successfully! Follow these steps to run the application:

1. Ensure your virtual environment is activated:
   source venv/bin/activate

2. Set the environment variables:
   Create a .env file in the project root with the following content:
     SECRET_KEY=your_secret_key

3. Start the Flask application:
   flask run

4. Use the following endpoints:
   - Register: POST http://127.0.0.1:5000/register (JSON: {"username": "your_username", "password": "your_password"})
   - Login: POST http://127.0.0.1:5000/login (JSON: {"username": "your_username", "password": "your_password"})
   - Change Password: POST http://127.0.0.1:5000/change-password (JWT token required, JSON: {"old_password": "your_old_password", "new_password": "your_new_password"})
   - Dashboard: GET http://127.0.0.1:5000/dashboard (JWT token required)

INSTRUCTIONS
