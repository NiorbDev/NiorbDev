$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assets = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets'

function Get-PhotoDataUri($name, $width) {
    $source = [Drawing.Image]::FromFile((Join-Path $assets $name))
    $height = [int][Math]::Round($source.Height * $width / $source.Width)
    $preview = [Drawing.Bitmap]::new($width, $height)
    $graphics = [Drawing.Graphics]::FromImage($preview)
    $stream = [IO.MemoryStream]::new()
    try {
        $graphics.InterpolationMode = 'HighQualityBicubic'
        $graphics.DrawImage($source, 0, 0, $width, $height)
        $preview.Save($stream, [Drawing.Imaging.ImageFormat]::Jpeg)
        return 'data:image/jpeg;base64,' + [Convert]::ToBase64String($stream.ToArray())
    } finally {
        $stream.Dispose()
        $graphics.Dispose()
        $preview.Dispose()
        $source.Dispose()
    }
}

$defs = @"
<filter id="grain" x="0" y="0" width="100%" height="100%">
  <feTurbulence type="fractalNoise" baseFrequency=".76" numOctaves="3" seed="7" stitchTiles="stitch"/>
  <feColorMatrix type="saturate" values="0"/>
</filter>
<pattern id="ink" width="180" height="150" patternUnits="userSpaceOnUse">
  <path d="M3 13l23-6m110 47l18 2M26 123l22-2m64-36l10-3M170 139l8-1" stroke="#f7f0dc" stroke-width="1" opacity=".23"/>
  <rect width="180" height="150" filter="url(#grain)" opacity=".15"/>
</pattern>
<style><![CDATA[
  .headline { font-family: 'Montserrat', 'Arial Black', Arial, sans-serif; font-weight: 900; fill: #f7f0dc; }
  .editorial { font-family: 'Bodoni Moda', Georgia, serif; font-style: italic; }
  .brush { fill:#ffd044; }
  .frame { fill:none;stroke:#e7d6b8;stroke-width:2; }
  @media (prefers-reduced-motion: no-preference) {
    .reveal { animation: ink-in .34s cubic-bezier(.28,.75,.26,1) both; }
    .projects { animation: slide-in .6s cubic-bezier(.28,.75,.26,1) both; }
  }
  @keyframes ink-in { from { opacity: .15; transform: translateX(-12px); } to { opacity: 1; transform: translateX(0); } }
  @keyframes slide-in { from { opacity: .35; transform: translateX(-26px); } to { opacity: 1; transform: translateX(0); } }
]]></style>
"@

function Write-Panel($name, $height, $body, $extraDefs = '') {
    $content = @"
<svg xmlns="http://www.w3.org/2000/svg" width="960" height="$height" viewBox="0 0 960 $height">
<defs>$defs$extraDefs</defs>
<rect width="960" height="$height" fill="#101114"/>
<rect width="960" height="$height" fill="url(#ink)"/>
$body
<path class="frame" opacity=".8" d="M18 7H939l13 10v$($height-35)l-11 11H19L7 $($height-18)V19Z"/>
<path d="M8 44l18-28 28-8M907 $($height-7)l38-15 8-18" stroke="#f7f0dc" fill="none" opacity=".45"/>
</svg>
"@
    [IO.File]::WriteAllText((Join-Path $assets "$name.svg"), $content)
}

$portrait = Get-PhotoDataUri 'retrato.png' 760
Write-Panel 'editorial-portada' 415 @"
<image href="$portrait" x="475" y="8" width="477" height="620" preserveAspectRatio="xMidYMin slice"/>
<path d="M25 260H554l-15 8 11 5-23 4 8 6-25 12H33l8-7-15-4 11-8-14-2Z" class="brush reveal"/>
<path d="M28 312H405l-15 7 11 5-23 9 7 9H34l9-8-20-5 12-8Z" class="brush reveal"/>
<path d="M26 58H479l-28 4-47 2H26Z" class="brush"/>
<text x="31" y="170" class="headline" font-size="109" letter-spacing="-5">NiorbDev</text>
<text x="39" y="229" class="editorial" fill="#f7f0dc" font-size="48">Nicolas Orellana</text>
<text x="49" y="285" class="editorial" fill="#101114" font-size="25">Ingeniería Civil en Informática · USACH</text>
<text x="49" y="336" class="editorial" fill="#101114" font-size="25">Software y automatización</text>
"@

$cards = @(
    @{ Name = 'EntreCapas'; Image = 'entrecapas-probador.png'; Y = -40 },
    @{ Name = 'NiorbOS'; Image = ''; Y = 0 },
    @{ Name = 'Fitamon'; Image = 'fitamon-premio.png'; Y = -115 },
    @{ Name = 'Widget Diario'; Image = 'widget-pantalla-inicio.png'; Y = -12 }
)
$clips = @()
$panels = @()
for ($i = 0; $i -lt $cards.Count; $i++) {
    $card = $cards[$i]
    $x = 22 + 226 * $i
    $points = "$($x+34),78 $($x+225),78 $($x+191),326 $x,326"
    $clips += "<clipPath id='card$i'><polygon points='$points'/></clipPath>"
    $photo = if ($card.Image) {
        $data = Get-PhotoDataUri $card.Image 390
        "<image href='$data' x='$x' y='$($card.Y)' width='225' height='450' preserveAspectRatio='xMidYMin slice'/>"
    } else {
        "<rect x='$x' y='78' width='225' height='248' fill='#24262d'/><rect x='$x' y='78' width='225' height='248' fill='url(#ink)'/>"
    }
    $panels += @"
<g clip-path="url(#card$i)">
  $photo
  <rect x="$x" y="274" width="225" height="54" fill="#f7f0dc"/>
  <path class="brush" d="M$x 274h32l-9 54h-32z"/>
</g>
<polygon points="$points" class="frame"/>
<text x="$($x+35)" y="308" font-family="Montserrat, Arial, sans-serif" font-weight="900" font-size="23" fill="#101114">$($card.Name)</text>
"@
}
Write-Panel 'editorial-proyectos' 350 @"
<path class="brush" d="M35 28h26l-6 24H29Z"/>
<text x="76" y="53" class="headline" font-size="40">Proyectos</text>
<path d="M299 48H919" stroke="#e7d6b8" opacity=".65"/>
<g class="projects">$($panels -join '')</g>
"@ ($clips -join '')

foreach ($panel in @('Filosofía', 'Stack', 'Contribuciones', 'Contacto')) {
    $slug = $panel.ToLowerInvariant().Replace('í','i')
    Write-Panel "editorial-$slug" 92 @"
<path class="brush" d="M29 24h32l-6 43H24Z"/>
<text x="81" y="62" class="headline" font-size="43">$panel</text>
<path d="M430 57H915m-22-10h22" stroke="#e7d6b8" opacity=".65"/>
"@
}
