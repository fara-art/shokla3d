param(
    [Parameter(Mandatory = $true)]
    [string]$ReceiverIp
)

Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PaintWindow {
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr window, out Rect rect);
}
'@

$paint = Get-Process mspaint -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
    Select-Object -First 1
if (-not $paint) {
    Start-Process mspaint
    for ($attempt = 0; $attempt -lt 20 -and -not $paint; $attempt++) {
        Start-Sleep -Milliseconds 500
        $paint = Get-Process mspaint -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
            Select-Object -First 1
    }
}
if (-not $paint) { throw 'Ne udalos nayti okno Paint.' }

$client = New-Object System.Net.Sockets.TcpClient
try {
    $client.Connect($ReceiverIp, 8765)
    $client.NoDelay = $true
    $network = $client.GetStream()
    Write-Host 'Peredayu okno Paint. Ostavte ego vidimym; dlya ostanovki zakroyte eto okno.'

    while ($client.Connected) {
        $paint.Refresh()
        if ($paint.HasExited -or $paint.MainWindowHandle -eq [IntPtr]::Zero) { break }

        $rect = New-Object PaintWindow+Rect
        if ([PaintWindow]::GetWindowRect($paint.MainWindowHandle, [ref]$rect)) {
            $width = $rect.Right - $rect.Left
            $height = $rect.Bottom - $rect.Top
            if ($width -gt 0 -and $height -gt 0 -and $width -le 4096 -and $height -le 4096) {
                $bitmap = [System.Drawing.Bitmap]::new($width, $height)
                $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                $memory = [System.IO.MemoryStream]::new()
                try {
                    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
                    $bitmap.Save($memory, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                    $bytes = $memory.ToArray()
                    $length = [BitConverter]::GetBytes([int]$bytes.Length)
                    $network.Write($length, 0, 4)
                    $network.Write($bytes, 0, $bytes.Length)
                } finally {
                    $memory.Dispose()
                    $graphics.Dispose()
                    $bitmap.Dispose()
                }
            }
        }
        Start-Sleep -Milliseconds 500
    }
} finally {
    $client.Close()
}
