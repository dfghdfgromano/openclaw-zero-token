[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

$ROOT      = "C:\Users\21\openclaw-zero-token-main"
$STATE_DIR = "$ROOT\.openclaw-upstream-state"
$CONFIG    = "$STATE_DIR\openclaw.json"
$PORT      = "3002"
$TOKEN     = "62b791625fa441be036acd3c206b7e14e2bb13c803355823"
$WEB_URL   = "http://127.0.0.1:$PORT/chat?session=$TOKEN"

# Chrome path
$CHROME = ""
@("C:\Program Files\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | ForEach-Object {
    if ((Test-Path $_) -and $CHROME -eq "") { $CHROME = $_ }
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="OpenClaw Launcher"
        Width="480" Height="540"
        ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen"
        Background="#1e1e2e">
  <StackPanel Margin="32,24,32,24">
    <TextBlock Text="OpenClaw Zero Token" FontSize="20" FontWeight="Bold"
               Foreground="#cdd6f4" HorizontalAlignment="Center" Margin="0,0,0,4"/>
    <TextBlock Text="Quick Launch Panel" FontSize="12" Foreground="#6c7086"
               HorizontalAlignment="Center" Margin="0,0,0,24"/>

    <Button Name="BtnChrome"  Content="[1]  Start Chrome Debug Mode"       Height="52" Margin="0,0,0,10" FontSize="13" FontWeight="SemiBold" Foreground="White" Background="#313244" BorderThickness="0" Cursor="Hand"/>
    <Button Name="BtnAuth"    Content="[2]  Authorize AI Models (webauth)" Height="52" Margin="0,0,0,10" FontSize="13" FontWeight="SemiBold" Foreground="White" Background="#313244" BorderThickness="0" Cursor="Hand"/>
    <Button Name="BtnGateway" Content="[3]  Start Gateway"                 Height="52" Margin="0,0,0,10" FontSize="13" FontWeight="SemiBold" Foreground="White" Background="#313244" BorderThickness="0" Cursor="Hand"/>
    <Button Name="BtnWebUI"   Content="[4]  Open Web UI"                   Height="52" Margin="0,0,0,20" FontSize="13" FontWeight="SemiBold" Foreground="White" Background="#89b4fa" BorderThickness="0" Cursor="Hand"/>
    <Button Name="BtnStop"    Content="[Stop]  Stop Gateway"               Height="40" Margin="0,0,0,10" FontSize="12" Foreground="#f38ba8"  Background="#313244" BorderThickness="0" Cursor="Hand"/>
    <Button Name="BtnUpdate"  Content="[Update]  Pull latest &amp; rebuild"  Height="40" Margin="0,0,0,0"  FontSize="12" Foreground="#a6e3a1"  Background="#313244" BorderThickness="0" Cursor="Hand"/>
  </StackPanel>
</Window>
'@

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$win    = [Windows.Markup.XamlReader]::Load($reader)

foreach ($n in @("BtnChrome","BtnAuth","BtnGateway","BtnStop","BtnUpdate")) {
    $b = $win.FindName($n)
    $b.Add_MouseEnter({ $this.Background = "#45475a" })
    $b.Add_MouseLeave({ $this.Background = "#313244" })
}
$wu = $win.FindName("BtnWebUI")
$wu.Add_MouseEnter({ $this.Background = "#74c7ec" })
$wu.Add_MouseLeave({ $this.Background = "#89b4fa" })

# ── [1] Chrome debug mode ──────────────────────────────────────
$win.FindName("BtnChrome").Add_Click({
    $chromePath = $CHROME
    $profileDir = "$env:USERPROFILE\.openclaw-chrome-profile"
    $urls = "https://claude.ai/new https://chatgpt.com https://www.doubao.com/chat/ https://chat.qwen.ai https://www.kimi.com https://gemini.google.com/app https://grok.com https://chat.deepseek.com/ https://chatglm.cn"
    $bat = @"
@echo off
title [1] Chrome Debug Mode - Keep Open
cd /d "$ROOT"
echo Starting Chrome debug mode on port 9222...
echo Keep this window open!
echo.
start "" "$chromePath" --remote-debugging-port=9222 --user-data-dir="$profileDir" --no-first-run --no-default-browser-check --remote-allow-origins=* $urls
echo Chrome launched. Login to each platform in the browser tabs.
echo.
pause
"@
    $tmp = "$env:TEMP\openclaw_chrome.bat"
    $bat | Set-Content $tmp -Encoding ASCII
    Start-Process cmd -ArgumentList "/k `"$tmp`""
})

# ── [2] webauth ────────────────────────────────────────────────
$win.FindName("BtnAuth").Add_Click({
    $bat = @"
@echo off
title [2] Authorize AI Models
cd /d "$ROOT"
set OPENCLAW_CONFIG_PATH=$CONFIG
set OPENCLAW_STATE_DIR=$STATE_DIR
set OPENCLAW_GATEWAY_PORT=$PORT
echo Running webauth wizard...
echo.
node openclaw.mjs webauth
pause
"@
    $tmp = "$env:TEMP\openclaw_auth.bat"
    $bat | Set-Content $tmp -Encoding ASCII
    Start-Process cmd -ArgumentList "/k `"$tmp`""
})

# ── [3] Gateway ────────────────────────────────────────────────
$win.FindName("BtnGateway").Add_Click({
    $bat = @"
@echo off
title [3] OpenClaw Gateway - Keep Open
cd /d "$ROOT"
set OPENCLAW_CONFIG_PATH=$CONFIG
set OPENCLAW_STATE_DIR=$STATE_DIR
set OPENCLAW_GATEWAY_PORT=$PORT
echo Starting Gateway on port $PORT...
echo Keep this window open!
echo.
node openclaw.mjs gateway
"@
    $tmp = "$env:TEMP\openclaw_gateway.bat"
    $bat | Set-Content $tmp -Encoding ASCII
    Start-Process cmd -ArgumentList "/k `"$tmp`""
})

# ── [4] Web UI ─────────────────────────────────────────────────
$win.FindName("BtnWebUI").Add_Click({
    Start-Process $WEB_URL
    [System.Windows.MessageBox]::Show(
        "Web UI opened in browser.`n`nIf token mismatch, paste in top-right input:`n`n$TOKEN",
        "Web UI","OK","Information")
})

# ── [Stop] ─────────────────────────────────────────────────────
$win.FindName("BtnStop").Add_Click({
    $bat = @"
@echo off
title [Stop] Gateway
cd /d "$ROOT"
set OPENCLAW_CONFIG_PATH=$CONFIG
set OPENCLAW_STATE_DIR=$STATE_DIR
echo Stopping gateway...
node openclaw.mjs gateway stop
echo Done.
timeout /t 3
"@
    $tmp = "$env:TEMP\openclaw_stop.bat"
    $bat | Set-Content $tmp -Encoding ASCII
    Start-Process cmd -ArgumentList "/k `"$tmp`""
})

# ── [Update] ────────────────────────────────────────────────────
$win.FindName("BtnUpdate").Add_Click({
    $bat = @"
@echo off
title [Update] OpenClaw
cd /d "$ROOT"
echo Pulling latest from your fork (dfghdfgromano/openclaw-zero-token)...
git remote set-url origin https://github.com/dfghdfgromano/openclaw-zero-token.git
git pull origin main
if %errorlevel% neq 0 (
    echo Git pull failed. Trying to reset to origin/main...
    git fetch origin
    git checkout -B main --track origin/main --force
    git pull origin main
)
echo.
echo Installing dependencies...
call pnpm install
echo.
echo Building...
set OPENCLAW_A2UI_SKIP_MISSING=1
call node scripts/tsdown-build.mjs
call node scripts/copy-plugin-sdk-root-alias.mjs
call pnpm build:plugin-sdk:dts
call node --import tsx scripts/write-plugin-sdk-entry-dts.ts
call node --import tsx scripts/canvas-a2ui-copy.ts
call node --import tsx scripts/copy-hook-metadata.ts
call node --import tsx scripts/copy-export-html-templates.ts
call node --import tsx scripts/write-build-info.ts
call node --import tsx scripts/write-cli-startup-metadata.ts
call node --import tsx scripts/write-cli-compat.ts
call pnpm ui:build
echo.
echo Stopping old gateway (if running)...
node openclaw.mjs gateway stop 2>nul
echo.
echo Validating config...
node openclaw.mjs config validate
if %errorlevel% neq 0 (
    echo.
    echo [WARNING] Config validation failed! Check docs/zero-token-fixes.md for fix instructions.
    pause
    exit /b 1
)
echo.
echo Checking web-models plugin-sdk export...
node -e "const p=require('./package.json'); if(!p.exports['./plugin-sdk/web-models']){process.exit(1)}"
if %errorlevel% neq 0 (
    echo [FIX] web-models export missing from package.json, re-running copy-plugin-sdk-root-alias...
    call node scripts/copy-plugin-sdk-root-alias.mjs
    call node scripts/tsdown-build.mjs
    echo [FIX] web-models rebuild done.
)
echo Checking web-models dist file...
if not exist "dist\plugin-sdk\web-models.js" (
    echo [FIX] dist/plugin-sdk/web-models.js missing, rebuilding...
    call node scripts/copy-plugin-sdk-root-alias.mjs
    call node scripts/tsdown-build.mjs
    echo [FIX] Rebuild done.
)
echo.
echo Update + build complete! All checks passed. Now click [3] to restart gateway.
pause
"@
    $tmp = "$env:TEMP\openclaw_update.bat"
    $bat | Set-Content $tmp -Encoding ASCII
    Start-Process cmd -ArgumentList "/k `"$tmp`""
})

$win.ShowDialog() | Out-Null
