# Rebuild native Android branding from the existing TV Score vector logo.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$resRoot = Join-Path $projectRoot 'android/app/src/main/res'
$utf8 = [System.Text.UTF8Encoding]::new($false)
[xml]$logo = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'lib/assets/logoTvScore.svg'))
$paths = @($logo.DocumentElement.ChildNodes | Where-Object { $_.LocalName -eq 'path' })
$gradients = @{}
foreach ($defs in $logo.DocumentElement.ChildNodes) {
    if ($defs.LocalName -eq 'defs') {
        foreach ($gradient in $defs.ChildNodes) {
            $gradients[$gradient.GetAttribute('id')] = $gradient
        }
    }
}

function Write-Resource([string]$relativePath, [string]$content) {
    $target = Join-Path $resRoot $relativePath
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    [System.IO.File]::WriteAllText($target, $content + "`n", $utf8)
}

function New-LogoVector([string]$width, [string]$height, [string]$viewportWidth, [string]$viewportHeight, [string]$transform, [bool]$symbolOnly, [bool]$background, [bool]$monochrome) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('<?xml version="1.0" encoding="utf-8"?>')
    $lines.Add('<!-- Generated from lib/assets/logoTvScore.svg by tool/generate_android_branding.ps1. -->')
    $lines.Add('<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt"')
    $lines.Add("    android:width=`"$width`" android:height=`"$height`" android:viewportWidth=`"$viewportWidth`" android:viewportHeight=`"$viewportHeight`">")
    if ($background) {
        $lines.Add('    <path android:fillColor="@color/tv_score_background" android:pathData="M0,0 H108 V108 H0 Z" />')
    }
    if ($transform) { $lines.Add("    <group $transform>") }
    $selectedPaths = if ($symbolOnly) { $paths | Select-Object -First 3 } else { $paths }
    foreach ($path in $selectedPaths) {
        $data = $path.GetAttribute('d')
        $fill = $path.GetAttribute('fill')
        if ($monochrome) { $fill = '#FFFFFF' }
        if ($fill.StartsWith('url(#')) {
            $id = $fill.Substring(5, $fill.Length - 6)
            $gradient = $gradients[$id]
            if ($null -eq $gradient) { throw "Missing gradient: $id" }
            $lines.Add("        <path android:pathData=`"$data`">")
            $lines.Add('            <aapt:attr name="android:fillColor">')
            $lines.Add("                <gradient android:type=`"linear`" android:startX=`"$($gradient.GetAttribute('x1'))`" android:startY=`"$($gradient.GetAttribute('y1'))`" android:endX=`"$($gradient.GetAttribute('x2'))`" android:endY=`"$($gradient.GetAttribute('y2'))`">")
            foreach ($stop in $gradient.ChildNodes) {
                $lines.Add("                    <item android:offset=`"$($stop.GetAttribute('offset'))`" android:color=`"$($stop.GetAttribute('stop-color'))`" />")
            }
            $lines.Add('                </gradient>')
            $lines.Add('            </aapt:attr>')
            $lines.Add('        </path>')
        } else {
            $lines.Add("        <path android:fillColor=`"$fill`" android:pathData=`"$data`" />")
        }
    }
    if ($transform) { $lines.Add('    </group>') }
    $lines.Add('</vector>')
    return $lines -join "`n"
}

# Keep the symbol inside Android's adaptive-icon safe area.
$adaptiveTransform = 'android:scaleX="0.18" android:scaleY="0.18" android:translateX="27" android:translateY="27.7"'
Write-Resource 'drawable/tv_score_foreground.xml' (New-LogoVector '108dp' '108dp' '108' '108' $adaptiveTransform $true $false $false)
Write-Resource 'drawable/tv_score_monochrome.xml' (New-LogoVector '108dp' '108dp' '108' '108' $adaptiveTransform $true $false $true)
Write-Resource 'mipmap-anydpi/ic_launcher.xml' (New-LogoVector '48dp' '48dp' '108' '108' 'android:scaleX="0.24" android:scaleY="0.24" android:translateX="18" android:translateY="19"' $true $true $false)
Write-Resource 'drawable/tv_score_splash_icon.xml' (New-LogoVector '288dp' '288dp' '108' '108' $adaptiveTransform $true $false $false)
Write-Resource 'drawable/tv_score_wordmark.xml' (New-LogoVector '240dp' '68dp' '1035' '292' '' $false $false $false)
Write-Resource 'drawable/tv_score_splash_brand.xml' (New-LogoVector '200dp' '80dp' '1035' '414' 'android:translateY="61"' $false $false $false)

Write-Resource 'values/branding.xml' @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="tv_score_background">#091426</color>
</resources>
"@

$adaptiveIcon = @"
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/tv_score_background" />
    <foreground android:drawable="@drawable/tv_score_foreground" />
</adaptive-icon>
"@
Write-Resource 'mipmap-anydpi-v26/ic_launcher.xml' $adaptiveIcon
Write-Resource 'mipmap-anydpi-v33/ic_launcher.xml' ($adaptiveIcon.Replace('</adaptive-icon>', "    <monochrome android:drawable=`"@drawable/tv_score_monochrome`" />`n</adaptive-icon>"))

$launchBackground = @"
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/tv_score_background" />
    <item android:width="240dp" android:height="68dp" android:gravity="center"
        android:drawable="@drawable/tv_score_wordmark" />
</layer-list>
"@
Write-Resource 'drawable/launch_background.xml' $launchBackground
Write-Resource 'drawable-v21/launch_background.xml' $launchBackground

$styles = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:statusBarColor">@color/tv_score_background</item>
        <item name="android:navigationBarColor">@color/tv_score_background</item>
        <item name="android:windowLightStatusBar">false</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/tv_score_background</item>
    </style>
</resources>
"@
Write-Resource 'values/styles.xml' $styles
Write-Resource 'values-night/styles.xml' $styles

$styles31 = $styles.Replace('        <item name="android:windowBackground">@drawable/launch_background</item>', @"
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/tv_score_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/tv_score_splash_icon</item>
        <item name="android:windowSplashScreenBrandingImage">@drawable/tv_score_splash_brand</item>
"@)
Write-Resource 'values-v31/styles.xml' $styles31
Write-Resource 'values-night-v31/styles.xml' $styles31

Write-Output 'Android branding resources generated.'
