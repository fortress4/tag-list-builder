param(
    [switch] $Check
)

$ErrorActionPreference = 'Stop'

$filePairs = @(
    @{ Source = 'js/tag-list-builder.js'; Destination = 'dist/js/tag-builder.js' },
    @{ Source = 'js/tag-list-builder-typeahead.js'; Destination = 'dist/js/tag-builder-typeahead.js' },
    @{ Source = 'css/tag-list-builder.css'; Destination = 'dist/css/tag-builder.css' }
)

foreach ($pair in $filePairs) {
    $sourcePath = Join-Path $PSScriptRoot $pair.Source
    $destinationPath = Join-Path $PSScriptRoot $pair.Destination

    if ($Check) {
        $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
        $destinationHash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash

        if ($sourceHash -ne $destinationHash) {
            throw "Distribution file is out of date: $($pair.Destination)"
        }

        Write-Output "Current: $($pair.Destination)"
        continue
    }

    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    Write-Output "Updated: $($pair.Destination)"
}

