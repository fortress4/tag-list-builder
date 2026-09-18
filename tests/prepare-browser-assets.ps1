$ErrorActionPreference = 'Stop'

$assetDirectory = Join-Path $PSScriptRoot '.cache'
New-Item -ItemType Directory -Force -Path $assetDirectory | Out-Null

$assets = @(
    @{ Name = 'jquery-4.0.0.min.js'; Url = 'https://code.jquery.com/jquery-4.0.0.min.js' },
    @{ Name = 'bootstrap-5.3.8.min.css'; Url = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css' },
    @{ Name = 'bootstrap-5.3.8.bundle.min.js'; Url = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js' },
    @{ Name = 'html5sortable-0.14.0.min.js'; Url = 'https://cdnjs.cloudflare.com/ajax/libs/html5sortable/0.14.0/html5sortable.min.js' },
    @{ Name = 'bootbox-6.0.4.min.js'; Url = 'https://cdnjs.cloudflare.com/ajax/libs/bootbox.js/6.0.4/bootbox.min.js' },
    @{ Name = 'jquery.typeahead-2.11.1.min.css'; Url = 'https://cdn.jsdelivr.net/npm/jquery-typeahead@2.11.1/dist/jquery.typeahead.min.css' },
    @{ Name = 'jquery.typeahead-2.11.1.min.js'; Url = 'https://cdn.jsdelivr.net/npm/jquery-typeahead@2.11.1/dist/jquery.typeahead.min.js' }
)

foreach ($asset in $assets) {
    $destination = Join-Path $assetDirectory $asset.Name
    Invoke-WebRequest -Uri $asset.Url -OutFile $destination
    Write-Output "Downloaded $($asset.Name)"
}

