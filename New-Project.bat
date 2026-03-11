@echo off
setlocal
title North Desktop Template
color 0F
set "TEMPLATE_REPO_URL=https://github.com/VX-Creative/north-desktop-template.git"
set "TEMPLATE_REPO_BRANCH=template"

rem Tenta atualizar os artefatos locais sem bloquear o uso offline.
call :TryGitPull

set "_payload=%temp%\NorthDesktop.NewProject.%random%%random%.ps1"
set "NORTH_TEMPLATE_ROOT=%~dp0"
for /f "tokens=1 delims=:" %%A in ('findstr /n /c:"# POWERSHELL_PAYLOAD_BEGIN" "%~f0"') do set "_startLine=%%A"
more +%_startLine% "%~f0" > "%_payload%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%_payload%" %*
set "_exitCode=%errorlevel%"

del /f /q "%_payload%" >nul 2>nul
if not "%_exitCode%"=="0" pause
exit /b %_exitCode%

:TryGitPull
where git >nul 2>nul
if errorlevel 1 (
    echo Git nao encontrado. Seguindo com os arquivos locais...
    goto :eof
)

echo Verificando atualizacoes do template...
git -C "%~dp0" rev-parse --is-inside-work-tree >nul 2>nul
if not errorlevel 1 (
    rem Atualiza pelo reposit??rio oficial quando o template foi clonado via Git.
    git -C "%~dp0" pull --ff-only "%TEMPLATE_REPO_URL%" "%TEMPLATE_REPO_BRANCH%"
    if errorlevel 1 (
        echo Nao foi possivel atualizar via git pull. Tentando baixar a versao mais recente...
        call :RefreshFromClone
    ) else (
        echo Template atualizado com sucesso.
    )
    goto :eof
)

rem Atualiza por clone temporario quando os arquivos foram copiados sem o .git.
call :RefreshFromClone
goto :eof

:RefreshFromClone
set "_updateRoot=%temp%\NorthDesktop.Template.Update.%random%%random%"
set "_updateRepo=%_updateRoot%\repo"

if exist "%_updateRoot%" rmdir /s /q "%_updateRoot%"
mkdir "%_updateRoot%" >nul 2>nul

git clone --depth 1 --single-branch --branch "%TEMPLATE_REPO_BRANCH%" "%TEMPLATE_REPO_URL%" "%_updateRepo%"
if errorlevel 1 (
    echo Nao foi possivel atualizar agora. Seguindo com a versao local...
    if exist "%_updateRoot%" rmdir /s /q "%_updateRoot%"
    goto :eof
)

rem Atualiza os artefatos principais antes de continuar a criacao do projeto.
if exist "%_updateRepo%\NorthDesktop.Template.zip" copy /y "%_updateRepo%\NorthDesktop.Template.zip" "%~dp0" >nul
if exist "%_updateRepo%\README.md" copy /y "%_updateRepo%\README.md" "%~dp0" >nul
if exist "%~dp0New-Project.latest.bat" del /f /q "%~dp0New-Project.latest.bat" >nul 2>nul
if exist "%_updateRepo%\New-Project.bat" copy /y "%_updateRepo%\New-Project.bat" "%~dp0New-Project.latest.bat" >nul

if exist "%~dp0New-Project.latest.bat" (
    move /y "%~dp0New-Project.latest.bat" "%~dp0New-Project.bat" >nul
)

if exist "%_updateRoot%" rmdir /s /q "%_updateRoot%"
echo Template atualizado com sucesso.
goto :eof

# POWERSHELL_PAYLOAD_BEGIN
param(
    [string]$ProjectName,
    [string]$DestinationPath
)

function Convert-ToNamespace {
    param([string]$Value)

    $segments = $Value -split '[^A-Za-z0-9]+'
    $cleanSegments = foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment)) { continue }

        $normalized = $segment.Substring(0, 1).ToUpperInvariant() + $segment.Substring(1)
        if ($normalized[0] -match '\d') {
            $normalized = "_$normalized"
        }

        $normalized
    }

    if (-not $cleanSegments) {
        return "NorthDesktopProject"
    }

    return ($cleanSegments -join '.')
}

$templateRoot = $env:NORTH_TEMPLATE_ROOT
$packageZipPath = Join-Path $templateRoot "NorthDesktop.Template.zip"

if (-not (Test-Path $packageZipPath)) {
    Write-Error "O arquivo NorthDesktop.Template.zip n??o foi encontrado."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Read-Host "Qual sera o nome do projeto"
}

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Error "Nome do projeto nao informado."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    $DestinationPath = Read-Host "Pasta de destino (vazio = usar esta pasta)"
}

if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    $DestinationPath = $templateRoot
}

[Console]::Title = "North Desktop Template"

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " North Desktop Template" -ForegroundColor White
Write-Host " Desenvolvido por Marcus Gaspar (c)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Iniciando criacao do projeto..." -ForegroundColor Cyan

$namespaceName = Convert-ToNamespace $ProjectName
$temporaryExtractPath = Join-Path $env:TEMP ("NorthDesktopTemplate_" + [guid]::NewGuid().ToString("N"))
$targetRootPath = Join-Path $DestinationPath $ProjectName
$targetPackagesPath = Join-Path $targetRootPath "packages"
$targetReadmePath = Join-Path $targetRootPath "README.md"
$targetProjectBuildPropsPath = Join-Path $targetRootPath "Configuration\Project.Build.props"
$solutionPath = Join-Path $targetRootPath "$ProjectName.slnx"

Expand-Archive -Path $packageZipPath -DestinationPath $temporaryExtractPath -Force
Write-Host "Template extraido." -ForegroundColor DarkGray

$templateProjectPath = Join-Path $temporaryExtractPath "NorthDesktop.Template"
$packagesPath = Join-Path $temporaryExtractPath "packages"
$readmePath = Join-Path $temporaryExtractPath "README.md"

if (-not (Test-Path $templateProjectPath)) {
    Write-Error "A estrutura do template nao foi encontrada dentro do zip."
    exit 1
}

if (Test-Path $targetRootPath) {
    Remove-Item -Recurse -Force $targetRootPath
}

New-Item -ItemType Directory -Force -Path $targetRootPath | Out-Null
Copy-Item -Recurse -Force (Join-Path $templateProjectPath "*") $targetRootPath
Copy-Item -Recurse -Force $packagesPath $targetPackagesPath
Copy-Item -Force $readmePath $targetReadmePath
Write-Host "Arquivos copiados." -ForegroundColor DarkGray

$oldProjectFile = Join-Path $targetRootPath "NorthDesktop.Template.csproj"
$newProjectFile = Join-Path $targetRootPath "$ProjectName.csproj"
$localPackageCachePath = Join-Path $targetRootPath ".nuget\packages\northdesktop.framework"

Rename-Item -Path $oldProjectFile -NewName "$ProjectName.csproj"

$filesToUpdate = Get-ChildItem $targetRootPath -Recurse -File |
    Where-Object { $_.Extension -in '.cs', '.xaml', '.csproj', '.md', '.json', '.config', '.props' }

foreach ($file in $filesToUpdate) {
    # Mantem acentos corretos ao transformar os arquivos do template.
    $content = Get-Content -Raw -Encoding UTF8 $file.FullName
    $content = $content.Replace("NorthDesktop.Template", $namespaceName)
    $content = $content.Replace("North Desktop Template", $ProjectName)
    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
}
Write-Host "Ajustes de nome e namespace aplicados." -ForegroundColor DarkGray

# Ajusta o nome tecnico inicial do projeto gerado.
[xml]$projectXml = Get-Content -Raw -Encoding UTF8 $newProjectFile
$propertyGroup = $projectXml.Project.PropertyGroup | Select-Object -First 1
if ($null -ne $propertyGroup) {
    $propertyGroup.AssemblyName = $ProjectName
    $propertyGroup.FileVersion = "0.0.0"
}
$projectXml.Save($newProjectFile)

# Mantem o namespace padrao valido sem expor mais configuracoes no csproj.
$projectBuildPropsContent = @"
<Project>
  <PropertyGroup>
    <!-- Mantem o namespace do projeto valido para o XAML. -->
    <RootNamespace>$namespaceName</RootNamespace>
  </PropertyGroup>
</Project>
"@
Set-Content -Path $targetProjectBuildPropsPath -Value $projectBuildPropsContent -Encoding UTF8

# Limpa artefatos da copia antes da primeira abertura do dev.
foreach ($folderName in @("bin", "obj")) {
    $folderPath = Join-Path $targetRootPath $folderName
    if (Test-Path $folderPath) {
        Remove-Item -Recurse -Force $folderPath
    }
}

# Cria a solution final para o dev ja abrir tudo pronto.
dotnet new sln -n $ProjectName -o $targetRootPath | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Nao foi possivel criar a solution."
    exit $LASTEXITCODE
}

if (-not (Test-Path $solutionPath)) {
    Write-Error "A solution criada nao foi encontrada."
    exit 1
}

dotnet sln $solutionPath add $newProjectFile | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Nao foi possivel adicionar o projeto na solution."
    exit $LASTEXITCODE
}
Write-Host "Solution criada." -ForegroundColor DarkGray

# Evita reaproveitar pacote local antigo quando a versao nao mudou.
if (Test-Path $localPackageCachePath) {
    Remove-Item -Recurse -Force $localPackageCachePath
}

# Forca restauracao limpa para garantir que o framework fechado esteja atualizado.
Write-Host "Restaurando pacotes (aguarde)..." -ForegroundColor Yellow
dotnet restore $newProjectFile -p:RestoreForce=true -p:RestoreNoCache=true
if ($LASTEXITCODE -ne 0) {
    Write-Error "Nao foi possivel restaurar os pacotes do projeto."
    exit $LASTEXITCODE
}
Write-Host "Pacotes restaurados." -ForegroundColor Green

Remove-Item -Recurse -Force $temporaryExtractPath

Write-Host ""
Write-Host "Projeto criado com sucesso." -ForegroundColor Green
Write-Host "Pasta: $targetRootPath"
Write-Host "Solution: $solutionPath"
Write-Host ""
Write-Host "Proximo passo:" -ForegroundColor White
Write-Host "1. Abrir o arquivo $ProjectName.slnx"
Write-Host "2. Compilar o projeto"
Write-Host "3. Comecar o desenvolvimento"

# Abre a pasta final pronta para o dev localizar a solution.
Start-Process explorer.exe $targetRootPath | Out-Null
