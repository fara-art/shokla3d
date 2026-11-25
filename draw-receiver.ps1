Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 8765)
$script:listener.Start()
$script:client = $null
$script:buffer = New-Object 'System.Collections.Generic.List[byte]'

$addresses = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) |
    Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork }
$addressText = ($addresses | ForEach-Object { $_.ToString() }) -join ', '

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Risunok iz Paint'
$form.Width = 900
$form.Height = 650
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Dock = 'Top'
$label.Height = 40
$label.Text = "IP etogo kompyutera: $addressText  |  Zapustite draw-send.bat na svoem kompyutere"
$form.Controls.Add($label)

$picture = New-Object System.Windows.Forms.PictureBox
$picture.Dock = 'Fill'
$picture.SizeMode = 'Zoom'
$form.Controls.Add($picture)
$label.BringToFront()

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    if ($script:listener.Pending()) {
        if ($script:client) { $script:client.Close() }
        $script:client = $script:listener.AcceptTcpClient()
        $script:buffer.Clear()
    }
    if (-not $script:client) { return }

    try {
        $stream = $script:client.GetStream()
        while ($stream.DataAvailable) {
            $chunk = New-Object byte[] 65536
            $count = $stream.Read($chunk, 0, $chunk.Length)
            if ($count -le 0) { break }
            $part = New-Object byte[] $count
            [Array]::Copy($chunk, $part, $count)
            $script:buffer.AddRange($part)
        }

        while ($script:buffer.Count -ge 4) {
            $header = $script:buffer.GetRange(0, 4).ToArray()
            $length = [BitConverter]::ToInt32($header, 0)
            if ($length -le 0 -or $length -gt 8000000) { throw 'Bad frame size' }
            if ($script:buffer.Count -lt 4 + $length) { break }
            $frame = $script:buffer.GetRange(4, $length).ToArray()
            $script:buffer.RemoveRange(0, 4 + $length)

            $memory = [System.IO.MemoryStream]::new($frame)
            try {
                $image = [System.Drawing.Image]::FromStream($memory)
                $next = [System.Drawing.Bitmap]::new($image)
                $image.Dispose()
                $old = $picture.Image
                $picture.Image = $next
                if ($old) { $old.Dispose() }
            } finally { $memory.Dispose() }
        }
    } catch {
        $script:client.Close()
        $script:client = $null
        $script:buffer.Clear()
    }
})
$form.Add_FormClosed({
    $timer.Stop()
    if ($script:client) { $script:client.Close() }
    $script:listener.Stop()
    if ($picture.Image) { $picture.Image.Dispose() }
})
$timer.Start()
[void]$form.ShowDialog()
