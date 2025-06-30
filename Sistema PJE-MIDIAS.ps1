# Cria pasta temporária
$temp = "$env:TEMP\InstaladoresPJE"
New-Item -Path $temp -ItemType Directory -Force | Out-Null

# Lista de programas para baixar e instalar
$programas = @(
    @{
        Nome = "Java x86"
        Url  = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244582_d7fc238d0cbf4b0dac67be84580cfb4b"
        Arquivo = "java_x86.exe"
        Args = "/s"
    },
    @{
        Nome = "PJe Mídias"
        Url  = "https://midias.pje.jus.br/midias/web/controle-versao/download?versao=1.4.0&tip_sistema_operacional=WIN64"
        Arquivo = "pje_midias.exe"
        Args = "/S"
    }
)

# Função para baixar e instalar
function Instalar-Programa($nome, $url, $arquivo, $args) {
    $caminho = Join-Path $temp $arquivo

    # Remove o arquivo antigo, se existir
    if (Test-Path $caminho) {
        try {
            Remove-Item $caminho -Force
        } catch {
            Write-Host "⚠ Não foi possível excluir arquivo existente: $caminho" -ForegroundColor Yellow
            return
        }
    }

    Write-Host "`n→ Baixando $nome..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $caminho -UseBasicParsing
    } catch {
        Write-Host "✖ Falha ao baixar ${nome}: $_" -ForegroundColor Red
        return
    }

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
        Write-Host "❌ Arquivo não encontrado após o download: $caminho" -ForegroundColor Red
    }
}

# Executa a instalação dos programas
foreach ($app in $programas) {
    Instalar-Programa -nome $app.Nome -url $app.Url -arquivo $app.Arquivo -args $app.Args
}

Write-Host "`n✅ Instalação finalizada." -ForegroundColor Green
