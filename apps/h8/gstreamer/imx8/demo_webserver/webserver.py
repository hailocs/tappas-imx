#!/usr/bin/env python3
import os
import subprocess
import signal
import sys
import glob
from flask import Flask, request, render_template_string, jsonify

# -----------------------------
# CONFIG / GLOBALS
# -----------------------------
app = Flask(__name__)

_ROOT_DIR = os.path.abspath(os.path.dirname(__file__))
_CMD_DIR = os.path.join(_ROOT_DIR, "scripts")

PORT = 80  # Use 8080 instead of 80 (non-root)
WELCOME_MSG = """************************
ASTRIAL demo task server
************************

Available demo scripts:
"""

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>ASTRIAL Demo Switcher</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        form { margin-top: 20px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .script-option { margin: 5px 0; }
        select { padding: 5px; font-size: 14px; min-width: 200px; }
        button { padding: 8px 20px; font-size: 14px; cursor: pointer; }
        .result { margin-top: 20px; padding: 10px; border: 1px solid #ccc; background: #f8f8f8; }
    </style>
</head>
<body>
    <h1>ASTRIAL Demo List</h1>
    <form method="post" action="/">
        <div class="form-group">
            <label>Select Script:</label>
            {% for script in scripts %}
                <div class="script-option">
                    <label>
                        <input type="radio" name="task" value="{{ script }}" {% if loop.first %}checked{% endif %}>
                        {{ script }}
                    </label>
                </div>
            {% endfor %}
        </div>

        <div class="form-group">
            <label for="camera">Camera Device:</label>
            <select name="camera" id="camera">
                {% for device in cameras %}
                    <option value="{{ device }}">{{ device }}</option>
                {% endfor %}
            </select>
        </div>

        <button type="submit">Switch</button>
    </form>

    {% if result %}
    <div class="result">
        <strong>Result:</strong><br>
        <pre>{{ result }}</pre>
    </div>
    {% endif %}
</body>
</html>
"""

STATUS_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Server Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .status { margin-top: 20px; padding: 10px; border: 1px solid #ccc; background: #f0f0f0; }
    </style>
</head>
<body>
    <h1>Server Status</h1>
    <div class="status">
        <strong>Currently running script:</strong><br>
        <pre>{{ current }}</pre>
    </div>
</body>
</html>
"""

# -----------------------------
# HELPERS
# -----------------------------
_current_script = None  # track the latest executed script

def list_scripts():
    os.makedirs(_CMD_DIR, exist_ok=True)
    scripts = []
    for f in os.listdir(_CMD_DIR):
        if f.endswith(".sh") and os.path.isfile(os.path.join(_CMD_DIR, f)):
            name, _ = os.path.splitext(f)
            scripts.append(name)
    scripts.sort()
    return scripts

def list_cameras():
    """List available /dev/video* devices (cameras only, not encoders/decoders)"""
    cameras = []
    video_devices = glob.glob("/dev/video*")
    
    for device in video_devices:
        try:
            # Use v4l2-ctl to check device capabilities
            result = subprocess.run(
                ["v4l2-ctl", "--device", device, "--all"],
                capture_output=True,
                text=True,
                timeout=2
            )
            output = result.stdout.lower()
            
            # Exclude memory-to-memory devices (encoders/decoders)
            if "memory-to-memory" in output:
                continue
            
            # Must have video capture capability (real camera)
            if "video capture" in output:
                cameras.append(device)
        except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
            # If v4l2-ctl fails or times out, skip this device
            continue
    
    cameras.sort()
    if not cameras:
        cameras = ["/dev/video2"]  # default fallback
    return cameras

def run_script_detached(script_name, client_ip, camera_device):
    global _current_script
    script_path = os.path.join(_CMD_DIR, f"{script_name}.sh")
    if not os.path.isfile(script_path):
        return False, "script not found"

    try:
        # Pass camera device as second argument to the script
        subprocess.Popen(
            ["bash", script_path, client_ip, camera_device],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
        _current_script = script_name
        return True, "ok"
    except Exception as e:
        return False, f"error: {e}"

# -----------------------------
# WEB UI
# -----------------------------
@app.route("/", methods=["GET", "POST"])
def index():
    scripts = list_scripts()
    cameras = list_cameras()
    result = None
    if request.method == "POST":
        task = request.form.get("task")
        camera = request.form.get("camera", "/dev/video0")
        client_ip = request.remote_addr
        success, msg = run_script_detached(task, client_ip, camera)
        result = f"{task}: {msg} (client {client_ip}, camera {camera})"
    return render_template_string(HTML_TEMPLATE, scripts=scripts, cameras=cameras, result=result)

# -----------------------------
# API ENDPOINTS (curl/wget)
# -----------------------------
@app.route("/demo/list", methods=["GET"])
@app.route("/demo/help", methods=["GET"])
def demo_list():
    scripts = list_scripts()
    return WELCOME_MSG + "\n".join(scripts), 200, {"Content-Type": "text/plain"}

@app.route("/demo/<task>", methods=["GET"])
def demo_task(task):
    client_ip = request.remote_addr
    camera = request.args.get("camera", "/dev/video0")
    success, msg = run_script_detached(task, client_ip, camera)
    if success:
        return msg, 200
    elif msg == "script not found":
        return msg, 404
    else:
        return msg, 500

# -----------------------------
# STATUS ENDPOINT
# -----------------------------
@app.route("/status", methods=["GET"])
def status():
    global _current_script
    current = _current_script or "none"

    fmt = request.args.get("format")
    accept = request.headers.get("Accept", "")

    if fmt == "json" or "application/json" in accept:
        return jsonify({"current_script": current})
    elif fmt == "text" or "text/plain" in accept:
        return current + "\n", 200, {"Content-Type": "text/plain"}
    else:
        return render_template_string(STATUS_TEMPLATE, current=current)

# -----------------------------
# ENTRY POINT
# -----------------------------
def signal_handler(sig, frame):
    print("\nShutting down server...")
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    print(f"Serving on port {PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=False)