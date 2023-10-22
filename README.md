# Cropsense - Leaf Disease Identification Mobile App

Cropsense is a mobile application designed for identifying leaf diseases in crops. This project consists of multiple components, including a backend server, two Flask APIs for different disease identification models, and the Flutter-based frontend application. Below are instructions on how to run these components locally for the finest experience.

## Project Structure

- **backend:** Node.js server handling backend requests, including the Chat GPT API requests.
- **Cropsense:** Flutter application serving as the frontend.
- **flask_api1:** Flask-based API for leaf disease identification (more accurate).
- **flask_api2:** Flask-based API for leaf disease identification.

## How to Run Locally

### 1. Backend

- **Command:** `node index.js`
- **Description:** Run the Node.js server to handle backend requests, including the Chat GPT API.

### 2. Flask API 1 (Leaf Disease Model 1)

- **Command:** `python app.py`
- **Description:** Start the Flask API for the first leaf disease identification model, which is more accurate.

### 3. Flask API 2 (Leaf Disease Model 2)

- **Commands:** 
   1. `cd src`
   2. `python app.py`
- **Description:** Run the Flask API for the second leaf disease identification model.

### 4. Cropsense (Flutter Application)

- **Steps:**
   1. Open the Cropsense project in Android Studio.
   2. Build and run the application.
   3. Ensure that the application is connected to the first model (Flask API 1) for more accurate disease identification.
