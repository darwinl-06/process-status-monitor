# Guardar como ProcessMonitor.ps1

# Configuración del puerto del servidor web
$port = 8080

# Función para generar la tabla HTML de procesos
function Get-ProcessHtmlTable {
    $processes = Get-Process | Select-Object Id, ProcessName, CPU, WorkingSet, StartTime
    $html = "<div class='table-responsive'><table class='process-table'>"
    $html += "<thead><tr><th>PID</th><th>Proceso</th><th>CPU</th><th>Memoria</th><th>Inicio</th><th>Acción</th></tr></thead><tbody>"

    foreach ($proc in $processes) {
        $memoria = [math]::Round($proc.WorkingSet / 1MB, 2)
        $cpu = [math]::Round($proc.CPU, 2)
        $inicio = if ($null -ne $proc.StartTime) { $proc.StartTime.ToString("dd/MM/yyyy HH:mm:ss") } else { "N/A" }
        
        $html += "<tr><td>$($proc.Id)</td><td>$($proc.ProcessName)</td><td>${cpu}%</td><td>${memoria} MB</td><td>$inicio</td>"
        $html += "<td><button class='kill-btn' onclick='terminateProcess($($proc.Id))'>Terminar</button></td></tr>"
    }
    
    $html += "</tbody></table></div>"
    return $html
}

# Función para generar la página HTML principal
function Get-PageContent {
    return @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitor de Procesos de Windows</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: #f0f2f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #1a56db;
            margin: 0 0 10px 0;
        }
        .table-responsive {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            overflow-x: auto;
        }
        .process-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        .process-table th {
            background: #f8fafc;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #475569;
            border-bottom: 2px solid #e2e8f0;
        }
        .process-table td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
        }
        .process-table tr:hover {
            background: #f8fafc;
        }
        .kill-btn {
            background: #dc2626;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
        }
        .kill-btn:hover {
            background: #b91c1c;
        }
        .status-bar {
            color: #6b7280;
            font-size: 14px;
        }
        .loading {
            text-align: center;
            padding: 20px;
            color: #6b7280;
        }
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
            if(confirm('¿Seguro que deseas terminar el proceso ' + pid + '?')) {
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
        <header>
            <h1>Monitor de Procesos de Windows</h1>
            <div class="status-bar">
                Actualizando cada 2 segundos
            </div>
        </header>
        <div id="processTable" class="loading">
            Cargando procesos...
        </div>
    </div>
</body>
</html>
"@
}

# Función para manejar las solicitudes HTTP
function Handle-Request {
    param ($context)
    
    $response = $context.Response
    $path = $context.Request.Url.AbsolutePath
    
    switch ($path) {
        "/" {
            $content = Get-PageContent
        }
        "/processes" {
            $content = Get-ProcessHtmlTable
        }
        "/kill" {
            $processId = [int]$context.Request.QueryString["pid"]
            try {
                Stop-Process -Id $processId -Force
                $content = "Proceso terminado exitosamente"
            }
            catch {
                $content = "Error al terminar el proceso"
            }
        }
        default {
            $response.StatusCode = 404
            $content = "Página no encontrada"
        }
    }

    $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}

# Crear y configurar el servidor HTTP
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Servidor iniciado en http://localhost:$port"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    Handle-Request $context
}