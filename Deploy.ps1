<# Deploy.ps1
   - 部署 latexmkrc 到用户文件夹 / *.sty 及 fonts 到 TeX Live
   - latexmkrc → %USERPROFILE%\.latexmkrc
   - *.sty → TEXMFLOCAL 可写则用,否则回退 TEXMFHOME
   - fonts → 仅 TEXMFLOCAL;不可写/无管理员直接提示并跳过
#>

#region Console & helpers
try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) } catch {}
try { chcp 65001 | Out-Null } catch {}

function Write-Log {
  param([ValidateSet('STEP','INFO','OK','WARN','ERROR')][string]$Level='INFO',[string]$Msg)
  $prefix = "[{0}] " -f $Level
  switch ($Level) {
    'ERROR' { Write-Host "$prefix$Msg" -ForegroundColor Red }
    'WARN'  { Write-Host "$prefix$Msg" -ForegroundColor Yellow }
    'OK'    { Write-Host "$prefix$Msg" -ForegroundColor Green }
    'STEP'  { Write-Host "$prefix$Msg" -ForegroundColor Cyan }
    default { Write-Host "$prefix$Msg" }
  }
}

function Test-WritableDir([string]$Path) {
  try {
    if (-not (Test-Path $Path)) { return $false }
    $tmp = Join-Path $Path ".__writetest__.tmp"
    'test' | Out-File -FilePath $tmp -Encoding ascii -Force
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    return $true
  } catch { return $false }
}

function Invoke-Tool([string]$Name,[string[]]$ToolArgs) {
  $exe = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $exe) { Write-Log WARN "$Name 未找到(可能未在 PATH 中)"; return $false }
  Write-Log STEP "运行 $Name $($ToolArgs -join ' ')"
  $p = Start-Process -FilePath $exe.Source -ArgumentList $ToolArgs -NoNewWindow -PassThru -Wait
  if ($p.ExitCode -ne 0) { Write-Log WARN "$Name 退出码 $($p.ExitCode)"; return $false }
  Write-Log OK "$Name 完成"; return $true
}

function Confirm-Yes([string]$Question) {
  $ans = Read-Host "$Question (Y/N, 默认 N)"
  return ($ans -match '^[Yy]$')
}
#endregion

#region Resolve script dir (robust)
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
  $scriptPath = $MyInvocation.MyCommand.Path
  if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    $ScriptDir = (Get-Location).Path
  } else {
    $ScriptDir = Split-Path -Path $scriptPath -Parent
  }
}
Write-Log STEP "脚本目录 Script dir: $ScriptDir"
#endregion

#region kpsewhich env
function Get-KpseVar($var) {
  $exe = Get-Command kpsewhich -ErrorAction SilentlyContinue
  if (-not $exe) { return $null }
  try {
    $val = & $exe.Source --var-value=$var 2>$null
    if ([string]::IsNullOrWhiteSpace($val)) { return $null }
    return $val.Trim()
  } catch { return $null }
}
$TEXMFLOCAL = Get-KpseVar 'TEXMFLOCAL'
$TEXMFHOME  = Get-KpseVar 'TEXMFHOME'
Write-Log STEP "TEXMFLOCAL = $TEXMFLOCAL"
Write-Log STEP "TEXMFHOME  = $TEXMFHOME"
Write-Host ""
#endregion

# 结果标记
$RC_Installed    = $false
$STY_Installed   = $false
$FONTS_Installed = $false
$FONTS_SkipReason = $null

#region 1) latexmkrc
if (Confirm-Yes "安装/更新 latexmkrc 到用户配置(%USERPROFILE%\.latexmkrc)?") {
  $srcRc = @(
    Join-Path $ScriptDir 'latexmkrc'
    Join-Path $ScriptDir '.latexmkrc'
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1

  $dstRc = Join-Path $env:USERPROFILE '.latexmkrc'
  if ($srcRc) {
    if (Test-Path $dstRc) { Write-Log INFO "检测到已存在:$dstRc,将覆盖" }
    else { Write-Log INFO "新安装:$dstRc" }
    Write-Log STEP "复制 latexmkrc 至 $dstRc"
    try { Copy-Item -Path $srcRc -Destination $dstRc -Force; Write-Log OK "latexmkrc 安装完成"; $RC_Installed = $true }
    catch { Write-Log ERROR "复制 latexmkrc 失败:$($_.Exception.Message)" }
  } else {
    Write-Log WARN "脚本目录未找到 latexmkrc 或 .latexmkrc,跳过"
  }
} else { Write-Log INFO "不安装 latexmkrc" }
Write-Host ""
#endregion

#region 2) *.sty
if (Confirm-Yes "安装/更新 *.sty 到 TeX Live?") {
  $styFiles = Get-ChildItem -LiteralPath $ScriptDir -Filter *.sty -File -ErrorAction SilentlyContinue
  if ($styFiles) {
    $targetTree = $null
    if ($TEXMFLOCAL -and (Test-WritableDir $TEXMFLOCAL)) {
      $targetTree = $TEXMFLOCAL; Write-Log STEP "安装 .sty 至(LOCAL):$targetTree"
    } else {
      if (-not $TEXMFHOME) { $TEXMFHOME = Join-Path $env:USERPROFILE 'texmf'; Write-Log INFO "默认 TEXMFHOME:$TEXMFHOME" }
      $targetTree = $TEXMFHOME; Write-Log STEP "回退安装 .sty 至(HOME):$targetTree"
    }
    $texlatex = Join-Path $targetTree 'tex\latex'
    if (-not (Test-Path $texlatex)) { Write-Log STEP "创建目录:$texlatex"; New-Item -ItemType Directory -Path $texlatex -Force | Out-Null }

    foreach ($f in $styFiles) {
      $pkgDir = Join-Path $texlatex ([IO.Path]::GetFileNameWithoutExtension($f.Name))
      if (-not (Test-Path $pkgDir)) { Write-Log STEP "创建包目录:$pkgDir"; New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null }
      $dst = Join-Path $pkgDir $f.Name
      if (Test-Path $dst) { Write-Log INFO "已存在(将覆盖):$dst" } else { Write-Log INFO "新安装:$dst" }
      Write-Log STEP "复制:$($f.Name) → $dst"
      try { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force; Write-Log OK "完成:$($f.Name)"; $STY_Installed = $true }
      catch { Write-Log ERROR "复制失败 $($f.Name):$($_.Exception.Message)" }
    }
  } else {
    Write-Log WARN "未发现 .sty,跳过样式安装"
  }
} else { Write-Log INFO "不安装 *.sty" }
Write-Host ""
#endregion

#region 3) fonts(仅 TEXMFLOCAL)
if (Confirm-Yes "安装/更新 fonts\\ 中的字体到 TeX Live?(需要管理员权限)") {
  $fontsSrc = Join-Path $ScriptDir 'fonts'
  if (Test-Path $fontsSrc) {
    if (-not $TEXMFLOCAL) {
      $FONTS_SkipReason = "未找到 TEXMFLOCAL"; Write-Log WARN "$FONTS_SkipReason;无法安装字体"
      Write-Log WARN "请以管理员权限重试"
    } elseif (-not (Test-WritableDir $TEXMFLOCAL)) {
      $FONTS_SkipReason = "TEXMFLOCAL 不可写"
      Write-Log WARN "$FONTS_SkipReason;跳过字体安装"
      Write-Log WARN "请以管理员权限重试"
    } else {
      $fontsDstRoot = Join-Path $TEXMFLOCAL 'fonts'
      Write-Log STEP "安装字体到:$fontsDstRoot"
      New-Item -ItemType Directory -Path $fontsDstRoot -Force | Out-Null

      $catMap = @{
        '.otf'='opentype'; '.ttf'='truetype'; '.ttc'='truetype';
        '.pfb'='type1';    '.afm'='afm';      '.tfm'='tfm';
        '.vf' ='vf';       '.enc'='enc';      '.map'='map'
      }

      $all = Get-ChildItem -LiteralPath $fontsSrc -Recurse -File -ErrorAction SilentlyContinue
      foreach ($f in $all) {
        $ext = $f.Extension.ToLowerInvariant()
        if (-not $catMap.ContainsKey($ext)) { continue }
        $cat = $catMap[$ext]

        $relDir = (Resolve-Path $f.Directory.FullName).Path.Substring((Resolve-Path $fontsSrc).Path.Length).TrimStart('\','/')
        $dstDir = Join-Path (Join-Path $fontsDstRoot $cat) $relDir
        if (-not (Test-Path $dstDir)) { Write-Log STEP "创建字体子目录:$dstDir"; New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

        $dstFile = Join-Path $dstDir $f.Name
        if (Test-Path $dstFile) { Write-Log INFO "字体已存在(将覆盖):$dstFile" } else { Write-Log INFO "安装新字体:$dstFile" }
        Write-Log STEP "复制字体:$($f.Name) → $dstFile"
        try { Copy-Item -LiteralPath $f.FullName -Destination $dstFile -Force; Write-Log OK "完成:$($f.Name)"; $FONTS_Installed = $true }
        catch { Write-Log ERROR "复制字体失败 $($f.Name):$($_.Exception.Message)" }

        if ($ext -in '.map','.enc') {
          foreach ($engine in @('pdftex','dvips')) {
            $sub = Join-Path (Join-Path $fontsDstRoot ($cat + '\' + $engine)) $relDir
            if (-not (Test-Path $sub)) { New-Item -ItemType Directory -Path $sub -Force | Out-Null }
            Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $sub $f.Name) -Force
          }
        }
      }
      if ($FONTS_Installed) { Write-Log OK "字体部署完成" }
      else { Write-Log INFO "未找到可识别的字体扩展名,字体部署未发生变更" }
    }
  } else {
    Write-Log WARN "未发现 fonts 目录,跳过字体安装"
  }
} else { Write-Log INFO "不安装 fonts" }
Write-Host ""
#endregion

#region 刷新动作(有任何安装才执行)
$didAnyInstall = ($RC_Installed -or $STY_Installed -or $FONTS_Installed)
if ($didAnyInstall) {
  Invoke-Tool mktexlsr @()       | Out-Null
  if ($FONTS_Installed) {
    if (Get-Command updmap-sys -ErrorAction SilentlyContinue) { Invoke-Tool updmap-sys @() | Out-Null }
    if (Get-Command luaotfload-tool -ErrorAction SilentlyContinue) { Invoke-Tool luaotfload-tool @('-u') | Out-Null }
  }
} else {
  Write-Log INFO "未执行任何安装操作,跳过刷新步骤"
}
#endregion

#region Summary
Write-Host ""
Write-Host "=================== 安装汇总 ==================="
Write-Host ("latexmkrc : " + ($(if($RC_Installed){"已安装"}else{"未安装"})))
Write-Host ("*.sty     : " + ($(if($STY_Installed){"已安装"}else{"未安装"})))
if ($FONTS_Installed) { Write-Host "fonts     : 已安装" }
elseif ($FONTS_SkipReason) { Write-Host ("fonts     : 未安装(原因:{0})" -f $FONTS_SkipReason) }
else { Write-Host "fonts     : 未安装" }
Write-Host "==========================================================="
[void](Read-Host "按回车退出 / Press Enter to exit")
#endregion
