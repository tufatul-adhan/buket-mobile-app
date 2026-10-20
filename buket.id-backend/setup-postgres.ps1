param(
    [string]$PsqlPath = 'D:\possql\bin\psql.exe'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $PsqlPath)) {
    throw "psql.exe tidak ditemukan di $PsqlPath. Jalankan dengan -PsqlPath 'PATH\psql.exe'."
}

$securePassword = Read-Host 'Password role PostgreSQL postgres' -AsSecureString
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    $databaseExists = & $PsqlPath -h localhost -p 5432 -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'buket_id'"
    if ($LASTEXITCODE -ne 0) { throw 'Gagal terhubung ke PostgreSQL.' }

    if ([string]::IsNullOrWhiteSpace(($databaseExists -join '').Trim())) {
        & $PsqlPath -h localhost -p 5432 -U postgres -d postgres -v ON_ERROR_STOP=1 -c 'CREATE DATABASE buket_id'
        if ($LASTEXITCODE -ne 0) { throw 'Gagal membuat database buket_id.' }
    }

    $schemaPath = Join-Path $PSScriptRoot 'migrations\schema.sql'
    & $PsqlPath -h localhost -p 5432 -U postgres -d buket_id -v ON_ERROR_STOP=1 -f $schemaPath
    if ($LASTEXITCODE -ne 0) { throw 'Gagal menerapkan skema PostgreSQL.' }
    Write-Host 'Database buket_id dan tabel aplikasi sudah siap.'
}
finally {
    $env:PGPASSWORD = $null
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
}
