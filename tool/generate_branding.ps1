# generate_branding.ps1 — raster derivatives of the Moon Resonance vector master
Add-Type -AssemblyName System.Drawing
$brandRoot = Join-Path $PSScriptRoot '../assets/branding'
New-Item -ItemType Directory -Force -Path $brandRoot | Out-Null
function New-HarmonixBitmap([bool]$Night, [bool]$Background) {
    $bitmap = [System.Drawing.Bitmap]::new(1024, 1024)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    if ($Background) { $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#0A0F2B')) }
    $graphics.ScaleTransform(8, 8)
    $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Point]::new(20,20), [System.Drawing.Point]::new(108,110),
        [System.Drawing.ColorTranslator]::FromHtml('#7B5CFF'), [System.Drawing.ColorTranslator]::FromHtml('#5EE6FF'))
    $blend = [System.Drawing.Drawing2D.ColorBlend]::new()
    $blend.Colors = @([System.Drawing.ColorTranslator]::FromHtml('#7B5CFF'), [System.Drawing.ColorTranslator]::FromHtml('#C8B4FF'), [System.Drawing.ColorTranslator]::FromHtml('#5EE6FF'))
    $blend.Positions = @(0.0, 0.5, 1.0)
    $brush.InterpolationColors = $blend
    $pen = [System.Drawing.Pen]::new($brush,17)
    $pen.StartCap = $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawLine($pen,28,28,28,100)
    $graphics.DrawLine($pen,100,$(if($Night){48}else{28}),100,100)
    $graphics.DrawBezier($pen,28,76,48,32,78,108,100,60)
    if ($Night) {
        $moon = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $moon.AddBezier(112,8,83,8,83,43,112,43)
        $moon.AddBezier(112,43,96,39,96,14,112,8)
        $moon.CloseFigure()
        $moonBrush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#C8B4FF'))
        $graphics.FillPath($moonBrush,$moon)
        $moonBrush.Dispose(); $moon.Dispose()
    }
    $graphics.Dispose(); $pen.Dispose(); $brush.Dispose()
    return $bitmap
}
$symbol = New-HarmonixBitmap $false $false
$symbol.Save((Join-Path $brandRoot 'harmonix-symbol.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$symbol.Save((Join-Path $PSScriptRoot '../assets/images/logo_harmonix.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$symbol.Save((Join-Path $PSScriptRoot '../android/app/src/main/res/drawable/logo_harmonix.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$icon = New-HarmonixBitmap $false $true
$icon.Save((Join-Path $brandRoot 'harmonix-icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$night = New-HarmonixBitmap $true $false
$night.Save((Join-Path $brandRoot 'harmonix-night-symbol.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$banner = [System.Drawing.Bitmap]::new(320,180)
$canvas = [System.Drawing.Graphics]::FromImage($banner)
$canvas.Clear([System.Drawing.ColorTranslator]::FromHtml('#0A0F2B'))
$canvas.DrawImage($symbol,8,30,120,120)
$font = [System.Drawing.Font]::new('Segoe UI',24,[System.Drawing.FontStyle]::Bold)
$canvas.DrawString('Harmonix',$font,[System.Drawing.Brushes]::White,128,65)
$banner.Save((Join-Path $PSScriptRoot '../android/app/src/main/res/drawable/tv_banner.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose(); $font.Dispose(); $banner.Dispose(); $symbol.Dispose(); $icon.Dispose(); $night.Dispose()
foreach($name in @('harmonix','harmonix-night')) {
    $master = Get-Content -Raw (Join-Path $brandRoot "$name.svg")
    $master.Replace('stroke="url(#flow)"','stroke="currentColor"').Replace('fill="#C8B4FF"','fill="currentColor"') | Set-Content (Join-Path $brandRoot "$name-mono.svg") -Encoding utf8
    $logotype = $master.Replace('viewBox="0 0 128 128"','viewBox="0 0 450 128"').Replace('</svg>', '<text x="144" y="78" font-family="sans-serif" font-size="40" letter-spacing="2" fill="currentColor">HARMONIX</text></svg>')
    $logotype | Set-Content (Join-Path $brandRoot "$name-logotype.svg") -Encoding utf8
}
Write-Output 'Generated Harmonix symbol, Night variant, icons, monochromes, logotypes and TV banner.'
