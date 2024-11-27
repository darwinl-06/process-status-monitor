#!/bin/bash

PORT=8080

cat <<'HTML' > process_monitor.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitor de Procesos de Linux</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: #f0f0f0;
        }
        .container {
            max-width: 800px;
            margin: auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f4f4f4; }
        .kill-btn { background-color: #e74c3c; color: white; border: none; padding: 5px 10px; border-radius: 5px; cursor: pointer; }
        .kill-btn:hover { background-color: #c0392b; }
    </style>
    <script>
        function updateProcessList() {
            fetch('/processes')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('processTable').innerHTML = data;
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('processTable').innerHTML = 'Error al cargar los procesos';
                });
        }

        function terminateProcess(pid) {
            if (confirm('¿Deseas terminar el proceso ' + pid + '?')) {
                fetch('/kill?pid=' + pid)
                    .then(response => response.text())
                    .then(data => {
                        alert(data);
                        updateProcessList();
                    });
            }
        }

        setInterval(updateProcessList, 2000);
        window.onload = updateProcessList;
    </script>
</head>
<body>
    <div class="container">
        <h1>Monitor de Procesos de Linux</h1>
        <div id="processTable">Cargando procesos...</div>
    </div>
</body>
</html>
HTML

python3 - <<'END_PYTHON'
import http.server
import socketserver
import subprocess
import urllib.parse
import os
import signal

PORT = 8080

class ProcessMonitorHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            with open('process_monitor.html', 'rb') as f:
                self.wfile.write(f.read())
        
        elif self.path == '/processes':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            # Generar tabla de procesos directamente
            try:
                processes_html = subprocess.check_output(
                    ["/bin/ps", "-eo", "pid,comm,%cpu,%mem", "--sort=-%cpu"],
                    universal_newlines=True
                )
                rows = ""
                for line in processes_html.splitlines()[1:51]:  # Limitar a 50 procesos
                    cols = line.split(None, 3)
                    pid, comm, cpu, mem = cols[0], cols[1], cols[2], cols[3]
                    rows += f"<tr><td>{pid}</td><td>{comm}</td><td>{cpu}%</td><td>{mem}%</td><td><button class='kill-btn' onclick='terminateProcess({pid})'>Terminar</button></td></tr>"
                html = f"<table><thead><tr><th>PID</th><th>Proceso</th><th>CPU</th><th>Memoria</th><th>Acción</th></tr></thead><tbody>{rows}</tbody></table>"
                self.wfile.write(html.encode())
            except Exception as e:
                self.wfile.write(f"Error al obtener procesos: {e}".encode())
        
        elif self.path.startswith('/kill'):
            query = urllib.parse.urlparse(self.path).query
            pid = urllib.parse.parse_qs(query).get('pid', [None])[0]
            if pid:
                try:
                    # Validar si el PID es un número y matar el proceso
                    if not pid.isdigit():
                        raise ValueError("PID no es un número válido")
                    os.kill(int(pid), signal.SIGTERM)
                    self.send_response(200)
                    self.send_header('Content-type', 'text/plain')
                    self.end_headers()
                    self.wfile.write(f'Proceso {pid} terminado exitosamente'.encode())
                except Exception as e:
                    self.send_response(500)
                    self.send_header('Content-type', 'text/plain')
                    self.end_headers()
                    self.wfile.write(f"Error al terminar el proceso {pid}: {str(e)}".encode())
            else:
                self.send_error(400, 'PID no especificado')
        else:
            self.send_error(404, 'Página no encontrada')

def run_server():
    with socketserver.TCPServer(("", PORT), ProcessMonitorHandler) as httpd:
        print(f"Servidor iniciado en http://localhost:{PORT}")
        httpd.serve_forever()

run_server()
END_PYTHON
