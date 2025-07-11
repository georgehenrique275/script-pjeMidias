# Instalação silenciosa do Java JRE 8u291 e PJE MIDIAS

# Reexecuta o script como Administrador se não estiver elevado
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Reexecutando como administrador..."
    $CommandLine = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $CommandLine
    exit
}

$global:JavaExePath = $null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry
    try {
        $LogEntry | Out-File -FilePath "$env:TEMP\PJE_MIDIAS_Install.log" -Append -Encoding UTF8
    } catch {
        Write-Host "Erro ao escrever no log: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-JavaX86 {
    Write-Log "Verificando versões anteriores do Java x86..."
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $paths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.DisplayName -like "*Java*Update*" -and $_.DisplayName -notlike "*64-bit*" -and $_.UninstallString) {
                try {
                    if ($_.UninstallString -match "msiexec") {
                        Start-Process msiexec.exe -ArgumentList "/x", $_.PSChildName, "/quiet", "/norestart" -Wait -WindowStyle Hidden
                    } else {
                        Start-Process $_.UninstallString -ArgumentList "/s" -Wait -WindowStyle Hidden
                    }
                    Write-Log "Java removido: $($_.DisplayName)"
                } catch {
                    Write-Log "Erro ao remover Java: $_" "ERROR"
                }
            }
        }
    }
}

function Install-JavaJRE {
    $temp = "$env:TEMP\jre-8u291"
    $exe = "$temp\jre-8u291-windows-i586.exe"
    $url = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244582_d7fc238d0cbf4b0dac67be84580cfb4b"
    New-Item -Path $temp -ItemType Directory -Force | Out-Null
    if (-not (Test-Path $exe)) {
        Write-Log "Baixando instalador do Java JRE..."
        Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    }
    Write-Log "Instalando Java JRE 8u291..."
    Start-Process -FilePath $exe -ArgumentList "/s", "INSTALL_SILENT=1", "AUTO_UPDATE=0", "REBOOT=0", "EULA=0", "REMOVEOUTOFDATEJRES=1" -Wait -WindowStyle Hidden
    $global:JavaExePath = "$env:ProgramFiles(x86)\Java\jre1.8.0_291\bin\java.exe"
    if (-not (Test-Path $global:JavaExePath)) { $global:JavaExePath = "java" }
    Write-Log "Java instalado em: $global:JavaExePath"
}

function Install-PJEMidias {
    $url = "https://midias.pje.jus.br/midias/web/controle-versao/download?versao=1.4.0&tip_sistema_operacional=WIN64"
    $dest = "$env:TEMP\ad-1.4.0.x64.exe"

    try {
        if (-not (Test-Path $dest)) {
            Write-Log "Baixando instalador do PJE MIDIAS..."
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
            Write-Log "Download concluído: $dest"
        } else {
            Write-Log "Instalador já existe: $dest"
        }

        if (Test-Path $dest) {
            Write-Log "Executando instalador do PJE MIDIAS..."
            Start-Process -FilePath $dest -Wait -WindowStyle Hidden
            Write-Log "Instalação concluída."
        } else {
            Write-Log "Erro: Instalador não encontrado em $dest"
        }
    } catch {
        Write-Log "Erro durante instalação: $($_.Exception.Message)"
    }
}

# Execução principal
Write-Log "=== INSTALAÇÃO JAVA + PJE MIDIAS INICIADA ==="
Remove-JavaX86
Install-JavaJRE
Write-Log "=== INÍCIO DA INSTALAÇÃO DO PJE MIDIAS ==="
Install-PJEMidias
Write-Log "=== FIM DA INSTALAÇÃO ==="

Read-Host "Pressione Enter para sair"
