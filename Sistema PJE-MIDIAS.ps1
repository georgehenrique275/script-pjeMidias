# Instalação silenciosa do Java Liberica JRE 8FULL e PJE MIDIAS

# Reexecuta o script como Administrador se não estiver elevado
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Reexecutando como administrador..."
    $CommandLine = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $CommandLine
    exit
}

function Write-Log($msg) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $msg"
}

function Remove-JavaX86 {
    Write-Log "Removendo instalações existentes do Java..."

    $javaApps = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "Java" -or $_.Name -match "JRE" -or $_.Name -match "OpenJDK" -or $_.Name -match "Liberica"
    }

    foreach ($app in $javaApps) {
        Write-Log "Desinstalando: $($app.Name)"
        try {
            $app.Uninstall() | Out-Null
            Write-Log "Removido com sucesso: $($app.Name)"
        } catch {
            Write-Log "Erro ao remover $($app.Name): $_"
        }
    }
}

function Install-JavaJRE {
    $javaUrl = "https://download.bell-sw.com/java/8u462+11/bellsoft-jre8u462+11-windows-amd64-full.msi"
    $installerPath = "$env:TEMP\bellsoft-jre8u462.msi"

    Write-Log "Baixando instalador do BellSoft Java JRE 8u462..."
    Invoke-WebRequest -Uri $javaUrl -OutFile $installerPath

    if (Test-Path $installerPath) {
        Write-Log "Instalador baixado com sucesso. Instalando em modo silencioso..."
        $installArgs = "/i `"$installerPath`" /qn /norestart"
        Start-Process "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow
        Write-Log "Instalação do Java concluída."
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    } else {
        Write-Log "Erro: Falha ao baixar o instalador. Verifique a URL."
    }
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
            Write-Log "Instalação do PJE MIDIAS concluída."
        } else {
            Write-Log "Erro: Instalador não encontrado em $dest"
        }
    } catch {
        Write-Log "Erro durante instalação do PJE MIDIAS: $($_.Exception.Message)"
    }
}

# Execução principal
Write-Log "=== INSTALAÇÃO JAVA + PJE MIDIAS INICIADA ==="
Remove-JavaX86
Install-JavaJRE
Write-Log "=== INÍCIO DA INSTALAÇÃO DO PJE MIDIAS ==="
Install-PJEMidias
Write-Log "=== FIM DA INSTALAÇÃO ==="
