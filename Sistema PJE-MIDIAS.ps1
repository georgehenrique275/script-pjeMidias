# Caminho temporário para armazenar instaladores
$temp = "$env:TEMP\InstaladoresPJE"
New-Item -Path $temp -ItemType Directory -Force | Out-Null

# Lista de programas
$programas = @(
    @{
        Nome    = "Java x86"
        Url     = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244582_d7fc238d0cbf4b0dac67be84580cfb4b"
        Arquivo = "java_x86.exe"
        Args    = "/s"
        Detect  = "Java 8 Update"
    },
    @{
        Nome    = "PJe Mídias"
        Url     = "https://midias.pje.jus.br/midias/web/controle-versao/download?versao=1.4.0&tip_sistema_operacional=WIN64"
        Arquivo = "pje_midias.exe"
        Args    = "/S"
        Detect  = "PJe Mídias"
    }
)

function Remover-Programa($nomeParcial) {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.DisplayName -and $_.DisplayName -like "*$nomeParcial*") {
                Write-Host "`n→ Encontrado '$($_.DisplayName)'. Removendo..." -ForegroundColor Yellow

                if ($_.UninstallString) {
                    try {
                        $uninstallCmd = $_.UninstallString
                        if ($uninstallCmd -match "msiexec") {
                            Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($_.PSChildName) /quiet /norestart" -Wait
                        } else {
                            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninstallCmd /quiet /norestart`"" -Wait
                        }
                        Write-Host "✔ $($_.DisplayName) removido com sucesso." -ForegroundColor Green
                    } catch {
                        Write-Host "✖ Falha ao remover $($_.DisplayName): $_" -ForegroundColor Red
                    }
                }
            }
        }
    }
}

function BaixarArquivo($url, $destino) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $destino)
        return $true
    } catch {
        Write-Host "✖ Falha no download: $_" -ForegroundColor Red
        return $false
    }
}

function Instalar-Programa($nome, $url, $arquivo, $args, $detect) {
    $caminho = Join-Path $temp $arquivo

    # Remover versões anteriores
    Remover-Programa $detect

    # Limpa o arquivo antigo se existir
    if (Test-Path $caminho) {
        try {
            Remove-Item $caminho -Force
        } catch {
            Write-Host "⚠ Não foi possível excluir instalador antigo: $caminho" -ForegroundColor Yellow
            return
        }
    }

    Write-Host "`n→ Baixando $nome..." -ForegroundColor Cyan
    $ok = BaixarArquivo $url $caminho
    if (-not $ok) { return }

    if (Test-Path $caminho) {
        Write-Host "✔ Instalando $nome..." -ForegroundColor Green
        try {
            if (![string]::IsNullOrWhiteSpace($args)) {
                Start-Process -FilePath $caminho -ArgumentList $args -Wait
            } else {
                Start-Process -FilePath $caminho -Wait
            }
        } catch {
            Write-Host "✖ Falha na instalação de ${nome}: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Arquivo não encontrado após download: $caminho" -ForegroundColor Red
    }
}

# Executar para cada programa
foreach ($app in $programas) {
    Instalar-Programa -nome $app.Nome -url $app.Url -arquivo $app.Arquivo -args $app.Args -detect $app.Detect
}

Write-Host "`n✅ Instalação finalizada." -ForegroundColor Green
