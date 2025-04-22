# 📸 Secure Flask Web App: Geolocation & Photo Logger

This project is a Dockerized Flask web application that captures a user's **geolocation** and a **photo from their webcam** when they download a file. All activity is logged and viewable via a web interface, including:

- 🌐 IP address
- 🗺️ Latitude / Longitude
- 🕒 Timestamp
- 🖼️ Captured photo
- 📍 Google Maps link to the location

---

## 🚀 Features

- ✅ Download trigger captures user geolocation and photo
- ✅ Saves all access logs to SQLite
- ✅ Displays access logs dynamically using JavaScript
- ✅ Includes Google Maps links per event
- ✅ HTTPS-enabled with a self-signed certificate
- ✅ Fully Dockerized for simple deployment

---

## 📦 Installation

### 1. Clone the repository and run the install script

```bash
chmod +x install_secure_flask_app_geo_plus_log.sh
./install_secure_flask_app_geo_plus_log.sh
cd secure-flask-app
docker-compose up --build

----

https://ip/
https://ip/geo.html
