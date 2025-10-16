# PowerShell script to remove PdfSharp-gdi references from .csproj file

Write-Host "?? Fixing PdfSharp reference conflicts..." -ForegroundColor Cyan

$csprojPath = "InventorySystemSiaProject\InventorySystemSiaProject.csproj"

if (!(Test-Path $csprojPath)) {
    Write-Host "? Project file not found at: $csprojPath" -ForegroundColor Red
    exit 1
}

Write-Host "?? Reading project file..." -ForegroundColor Yellow

# Read the .csproj file
$content = Get-Content $csprojPath -Raw

# Backup the original file
$backupPath = "$csprojPath.backup"
Copy-Item $csprojPath $backupPath -Force
Write-Host "?? Backup created at: $backupPath" -ForegroundColor Green

# Remove PdfSharp-gdi references
$patterns = @(
    # Pattern 1: Standard Reference block for PdfSharp-gdi
    '(?s)<Reference Include="PdfSharp-gdi[^"]*"[^>]*>.*?</Reference>',
    
    # Pattern 2: HintPath containing PdfSharp-MigraDoc-gdi
    '(?s)<Reference[^>]*>[\s\S]*?PdfSharp-MigraDoc-gdi[\s\S]*?</Reference>',
    
    # Pattern 3: Any Reference with MigraDoc in HintPath
    '(?s)<Reference Include="MigraDoc[^"]*"[^>]*>.*?</Reference>',
    
    # Pattern 4: Specific PdfSharp-gdi with version
    '(?s)<Reference Include="PdfSharp-gdi, Version=1\.50\.5147\.0[^"]*"[^>]*>.*?</Reference>'
)

$originalContent = $content
foreach ($pattern in $patterns) {
    $content = $content -replace $pattern, ''
}

# Clean up multiple consecutive blank lines
$content = $content -replace '(?m)^\s*\r?\n\s*\r?\n\s*\r?\n', "`r`n`r`n"

if ($content -ne $originalContent) {
    # Save the modified content
    Set-Content -Path $csprojPath -Value $content -Encoding UTF8
    Write-Host "? Removed PdfSharp-gdi references from project file" -ForegroundColor Green
} else {
    Write-Host "??  No PdfSharp-gdi references found to remove" -ForegroundColor Yellow
}

# Clean bin and obj folders
Write-Host "`n?? Cleaning build folders..." -ForegroundColor Cyan

$binPath = "InventorySystemSiaProject\bin"
$objPath = "InventorySystemSiaProject\obj"

if (Test-Path $binPath) {
    Remove-Item -Path $binPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "? Cleaned bin folder" -ForegroundColor Green
}

if (Test-Path $objPath) {
    Remove-Item -Path $objPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "? Cleaned obj folder" -ForegroundColor Green
}

# Remove MigraDoc package folder
Write-Host "`n?? Removing conflicting packages..." -ForegroundColor Cyan

$packagePaths = @(
    "packages\PdfSharp-MigraDoc-gdi*",
    "packages\MigraDoc*"
)

foreach ($pkgPath in $packagePaths) {
    $resolved = Resolve-Path $pkgPath -ErrorAction SilentlyContinue
    if ($resolved) {
        Remove-Item -Path $resolved -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "? Removed package: $pkgPath" -ForegroundColor Green
    }
}

Write-Host "`n? Fix completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Reload the project in Visual Studio (if open)" -ForegroundColor White
Write-Host "2. Build ? Clean Solution" -ForegroundColor White
Write-Host "3. Build ? Rebuild Solution" -ForegroundColor White
Write-Host "`nIf you need to restore the original file, it's backed up at:" -ForegroundColor Yellow
Write-Host "$backupPath" -ForegroundColor Gray
