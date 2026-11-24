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
Write-Panel 'editorial-portada' 568 @"
<path d="M35 126H437l-23 5 12 8-52 4H47l-16-8Z" class="brush reveal"/>
<path d="M36 423h259l-12 7 8 3-37 7H38l-11-8Z" class="brush reveal"/>
<image href="$portrait" x="496" y="22" width="424" height="524" preserveAspectRatio="xMidYMid meet"/>
<text x="37" y="291" class="headline" font-size="94" letter-spacing="-5">NiorbDev</text>
<text x="40" y="353" class="editorial" fill="#f7f0dc" font-size="42">Nicolas Orellana</text>
"@

$cards = @(
    @{ Name = 'EntreCapas'; Image = 'entrecapas-probador.png'; Y = 17 },
    @{ Name = 'Fitamon'; Image = 'fitamon-premio.png'; Y = -108 },
    @{ Name = 'Widget Diario'; Image = 'widget-pantalla-inicio.png'; Y = 32 }
)
$clips = @()
$panels = @()
for ($i = 0; $i -lt $cards.Count; $i++) {
    $card = $cards[$i]
    $x = 22 + 307 * $i
    $points = "$($x+42),78 $($x+297),78 $($x+255),326 $x,326"
    $clips += "<clipPath id='card$i'><polygon points='$points'/></clipPath>"
    $data = Get-PhotoDataUri $card.Image 440
    $panels += @"
<g clip-path="url(#card$i)">
  <image href="$data" x="$x" y="$($card.Y)" width="297" height="560" preserveAspectRatio="xMidYMin slice"/>
  <rect x="$x" y="274" width="297" height="54" fill="#f7f0dc"/>
  <path class="brush" d="M$($x+8) 274h35l-9 54h-35z"/>
</g>
<polygon points="$points" class="frame"/>
<text x="$($x+49)" y="309" font-family="Montserrat, Arial, sans-serif" font-weight="900" font-size="28" fill="#101114">$($card.Name)</text>
"@
}
Write-Panel 'editorial-proyectos' 350 @"
<path class="brush" d="M35 28h26l-6 24H29Z"/>
<text x="76" y="53" class="headline" font-size="40">Proyectos</text>
<path d="M299 48H919" stroke="#e7d6b8" opacity=".65"/>
<g class="projects">$($panels -join '')</g>
"@ ($clips -join '')

Write-Panel 'editorial-mosaico' 492 @"
<path class="frame" d="M24 22H412l13 12v219H24Z M24 270H425v195H36l-12-12Z M447 22H931v148H447Z M447 187H931v110H447Z M447 314H931v139l-12 12H447Z"/>
<path class="brush" d="M24 41h47l-10 17H24Z M24 293h38l-9 16H24Z M447 41h38l-9 17H447Z M447 208h38l-9 16H447Z M447 334h38l-9 16H447Z"/>
<text class="headline" x="84" y="75" font-size="38">Filosofía</text>
<text class="editorial" x="44" y="129" font-size="27" fill="#f7f0dc">
  <tspan x="44">Construyo aplicaciones</tspan><tspan x="44" dy="35">y automatizaciones para</tspan><tspan x="44" dy="35">resolver problemas cotidianos.</tspan>
</text>
<text class="headline" x="77" y="325" font-size="37">Stack</text>
<text x="44" y="379" fill="#f7f0dc" font-family="Arial, sans-serif" font-size="26">Java · C y C++ · Python</text>
<text x="44" y="423" fill="#f7f0dc" font-family="Arial, sans-serif" font-size="26">HTML y CSS</text>
<text class="headline" x="496" y="72" font-size="37">Contribuciones</text>
<text class="editorial" x="469" y="126" font-size="27" fill="#f7f0dc">Mi actividad en GitHub</text>
<text class="headline" x="496" y="237" font-size="35">Contacto</text>
<text class="editorial" x="469" y="273" font-size="23" fill="#f7f0dc">LinkedIn</text>
<text class="headline" x="496" y="372" font-size="31">Entre commits</text>
<text class="editorial" x="469" y="426" font-size="24" fill="#f7f0dc">Algo está soltando bloques…</text>
<path class="brush" d="M797 410h23v23h-23zm25 0h23v23h-23zm25 0h23v23h-23zm0-25h23v23h-23zm25-52h18v18h-18zm19 0h18v18h-18zm0 19h18v18h-18z"/>
"@