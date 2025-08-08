# Script para remover qualquer Java (exceto Liberica JRE 8 Full 64-bit), instalar a Liberica, configurar variáveis de ambiente e instalar o PJE Midias

# Caminho do instalador da Liberica JRE 8 Full (64-bit)
$msiUrl = "https://download.bell-sw.com/java/8u462+11/bellsoft-jre8u462+11-windows-amd64-full.msi"
$msiPath = "$env:TEMP\bellsoft-jre8u462+11-windows-amd64-full.msi"
$javaHomePath = "C:\Program Files\BellSoft\LibericaJDK-8-Full" # Caminho padrão de instalação do Liberica JRE 8 Full

# Função para log
function Write-Log {
    param($Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] $Message"
}

# Função para configurar variáveis de ambiente
function Set-JavaEnvironmentVariables {
    Write-Log "Configurando variáveis de ambiente para o Java..."

    try {
        # Definir JAVA_HOME
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHomePath, [System.EnvironmentVariableTarget]::Machine)
        Write-Log "JAVA_HOME configurado para: $javaHomePath"

        # Atualizar PATH
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        $javaBinPath = Join-Path $javaHomePath "bin"
        if ($currentPath -notlike "*$javaBinPath*") {
            $newPath = "$currentPath;$javaBinPath"
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
            Write-Log "Adicionado $javaBinPath ao PATH do sistema."
        } else {
            Write-Log "O caminho $javaBinPath já está no PATH."
        }

        # Verificar se o Java está acessível
        $javaVersion = & java -version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Java configurado corretamente. Versão: $javaVersion"
        } else {
            Write-Log "Erro: Java não está acessível após configuração."
        }
    } catch {
        Write-Log "Erro ao configurar variáveis de ambiente: $_"
    }
}

# Função para verificar e desinstalar qualquer Java, exceto Liberica JRE 8 Full (64-bit)
function Remove-AllJavaExceptLiberica {
    Write-Log "Verificando instalações de Java..."
    $installed = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "Java|JRE|JDK"
    }

    $LibericaInstalled = $false

    foreach ($product in $installed) {
        $name = $product.Name
        if ($name -like "Liberica JRE 8 Full*64-bit*") {
            Write-Log "Liberica JRE 8 Full (64-bit) encontrada. Mantendo..."
            $LibericaInstalled = $true
        } else {
            Write-Log "Desinstalando: $name"
            try {
                $product.Uninstall() | Out-Null
                Write-Log "Desinstalado com sucesso: $name"
            } catch {
                Write-Log "Erro ao desinstalar ${name}: $_"
            }
        }
    }

    return $LibericaInstalled
}

# Função para instalar Liberica JRE 8 Full (64-bit)
function Install-LibericaJRE {
    param (
        [bool]$LibericaInstalled
    )

    if (-not $LibericaInstalled) {
        Write-Log "Liberica JRE 8 Full (64-bit) não encontrada. Iniciando download e instalação..."

        try {
            # Baixar MSI
            Write-Log "Baixando instalador da Liberica JRE..."
            Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -ErrorAction Stop
            Write-Log "Download concluído: $msiPath"

            # Instalar MSI silenciosamente
            Write-Log "Instalando Liberica JRE 8 Full..."
            Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
            Write-Log "Instalação da Liberica JRE concluída."

            # Verificar se a instalação foi bem-sucedida
            $checkInstall = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "Liberica JRE 8 Full*64-bit*" }
            if ($checkInstall) {
                Write-Log "Verificação: Liberica JRE 8 Full (64-bit) instalada com sucesso."
            } else {
                Write-Log "Erro: Liberica JRE 8 Full (64-bit) não encontrada após instalação."
                return $false
            }
        } catch {
            Write-Log "Erro durante download ou instalação da Liberica JRE: $_"
            return $false
        } finally {
            # Limpar arquivo MSI
            if (Test-Path $msiPath) {
                Remove-Item $msiPath -Force
                Write-Log "Arquivo temporário $msiPath removido."
            }
        }

        return $true
    } else {
        Write-Log "Nenhuma instalação da Liberica JRE necessária."
        return $true
    }
}

# Função para instalar PJE Midias
function Install-PJEMidias {
    $url = "https://midias.pje.jus.br/midias/web/controle-versao/download?versao=1.4.0&tip_sistema_operacional=WIN64"
    $dest = "$env:TEMP\ad-1.4.0.x64.exe"

    try {
        if (-not (Test-Path $dest)) {
            Write-Log "Baixando instalador do PJE Midias..."
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
            Write-Log "Download concluído: $dest"
        } else {
            Write-Log "Instalador já existe: $dest"
        }

        if (Test-Path $dest) {
            Write-Log "Executando instalador do PJE Midias..."
            # Assumindo que o instalador suporta /S para instalação silenciosa
            Start-Process -FilePath $dest -ArgumentList "/S" -Wait -NoNewWindow
            Write-Log "Instalação do PJE Midias concluída."
        } else {
            Write-Log "Erro: Instalador não encontrado em $dest"
        }
    } catch {
        Write-Log "Erro durante instalação do PJE Midias: $($_.Exception.Message)"
    } finally {
        # Limpar arquivo temporário
        if (Test-Path $dest) {
            Remove-Item $dest -Force
            Write-Log "Arquivo temporário $dest removido."
        }
    }
}

# Execução principal
Write-Log "=== INSTALAÇÃO JAVA + PJE MIDIAS INICIADA ==="
$LibericaInstalled = Remove-AllJavaExceptLiberica
$JavaInstallSuccess = Install-LibericaJRE -LibericaInstalled $LibericaInstalled

if ($JavaInstallSuccess) {
    Set-JavaEnvironmentVariables
} else {
    Write-Log "Erro: Não foi possível instalar o Liberica JRE. Pulando configuração de variáveis de ambiente."
}

Write-Log "=== INÍCIO DA INSTALAÇÃO DO PJE MIDIAS ==="
Install-PJEMidias
Write-Log "=== FIM DA INSTALAÇÃO ==="

# Verificação final
Write-Log "Verificando configurações finais..."
$javaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", [System.EnvironmentVariableTarget]::Machine)
if ($javaHome -eq $javaHomePath) {
    Write-Log "JAVA_HOME está correto: $javaHome"
} else {
    Write-Log "Erro: JAVA_HOME não configurado corretamente. Atual: $javaHome"
}

$javaVersion = & java -version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Java acessível via linha de comando: $javaVersion"
} else {
    Write-Log "Erro: Java não acessível via linha de comando."
}
