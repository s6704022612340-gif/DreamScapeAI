$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Output "HTTP Server started successfully on port $port"
    Write-Output "URL: http://localhost:$port/"
} catch {
    Write-Error "Failed to start HttpListener: $_"
    exit 1
}

$cwd = Get-Location

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response

        $relPath = $req.Url.LocalPath.Trim('/')
        if ([string]::IsNullOrWhiteSpace($relPath)) {
            $relPath = "index.html"
        }

        $fullPath = Join-Path $cwd $relPath

        if (Test-Path -Path $fullPath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()

            switch ($ext) {
                ".html" { $res.ContentType = "text/html; charset=utf-8" }
                ".css"  { $res.ContentType = "text/css; charset=utf-8" }
                ".js"   { $res.ContentType = "application/javascript; charset=utf-8" }
                ".svg"  { $res.ContentType = "image/svg+xml" }
                ".json" { $res.ContentType = "application/json; charset=utf-8" }
                default { $res.ContentType = "application/octet-stream" }
            }

            $res.StatusCode = 200
            $res.ContentLength64 = $bytes.Length

            if ($req.HttpMethod -ne "HEAD") {
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } else {
            $res.StatusCode = 404
            $err = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $res.ContentLength64 = $err.Length
            if ($req.HttpMethod -ne "HEAD") {
                $res.OutputStream.Write($err, 0, $err.Length)
            }
        }
    } catch {
        # ignore client aborted errors
    } finally {
        if ($res -ne $null) {
            $res.Close()
        }
    }
}
