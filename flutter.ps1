$release_uri = "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$release_response = Invoke-RestMethod -Uri $release_uri -Method Get -Headers @{"Accept" = "application/json"; "Content-Type" = "application/json"} ; 
$release_counter = -1 ; 
# check if the last release is stable and not beta 
do {
    $release_counter++
    $last_release = $release_response.releases[$release_counter]
} while ($last_release.channel -ne "stable")

$download_prefix = "https://storage.googleapis.com/flutter_infra_release/releases"
$download_uri = "$download_prefix/$($last_release.archive)"

$file_name = Join-Path `
    ([System.IO.Path]::GetTempPath()) `
    "flutter.zip"

Write-Host "Flutter stable: $($last_release.version)"
Write-Host "Starting download..."
Write-Host ""
#start the download using BITS transfer to improve download speed
$job = Start-BitsTransfer `
    -Source $download_uri `
    -Destination $file_name `
    -DisplayName "Flutter Download" `
    -Description "Downloading Flutter stable release" `
    -Asynchronous

try {
    while ($true) {
        $job = Get-BitsTransfer -JobId $job.JobId

        $bytesTotal = [double]$job.BytesTotal
        $bytesTransferred = [double]$job.BytesTransferred

        if ($bytesTotal -gt 0) {
            $percent = ($bytesTransferred / $bytesTotal) * 100
        }
        else {
            $percent = 0
        }

        $mbTransferred = $bytesTransferred / 1MB
        $mbTotal = $bytesTotal / 1MB

        Write-Progress `
            -Activity "Downloading Flutter $($last_release.version)" `
            -Status ("{0:N1} MB / {1:N1} MB" -f $mbTransferred, $mbTotal) `
            -PercentComplete $percent

        if ($job.JobState -eq "Transferred") {
            Complete-BitsTransfer -BitsJob $job
            break
        }

        if ($job.JobState -eq "Error") {
            throw $job.Error.Description
        }

        if ($job.JobState -eq "Cancelled") {
            throw "Download cancelled."
        }

        Start-Sleep -Milliseconds 500
    }

    Write-Progress `
        -Activity "Downloading Flutter" `
        -Completed

    Write-Host ""
    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host "Saved to: $file_name"
}
catch {
    #stop the download if it is still running
    if ($job) {
        Remove-BitsTransfer -BitsJob $job -Confirm:$false -ErrorAction SilentlyContinue
    }

    Write-Progress -Activity "Downloading Flutter" -Completed

    if (Test-Path $file_name) {
        Remove-Item $file_name -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "Download stopped." -ForegroundColor Yellow
    exit 1
}
#extract the flutter SDK in desired diroctory 
if ([System.IO.File]::Exists($file_name)) {
    Write-Host ""
    Write-Host "Extracting Flutter SDK..."
    $extract_path = Join-Path `
        $env:USERPROFILE `
        "develop"

    if (-not (Test-Path $extract_path)) {
        New-Item -ItemType Directory -Path $extract_path -Force | Out-Null
    }

    $flutter_dir = Join-Path $extract_path "flutter"
    if (Test-Path $flutter_dir) {
        Remove-Item $flutter_dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Expand-Archive -Path $file_name -DestinationPath $extract_path -Force

    Write-Host ""
    Write-Host "Flutter SDK extracted to: $extract_path"
}
# add flutter to PATH permanently 
$flutter_bin = Join-Path `
    $env:USERPROFILE `
    "develop\flutter\bin"

$user_path = [Environment]::GetEnvironmentVariable("Path", "User")

if (($user_path -split ';') -notcontains $flutter_bin) {
    $new_user_path = if ([string]::IsNullOrWhiteSpace($user_path)) {
        $flutter_bin
    } else {
        "$user_path;$flutter_bin"
    }
    [Environment]::SetEnvironmentVariable("Path", $new_user_path, "User")
    Write-Host "Added to User PATH: $flutter_bin" -ForegroundColor Green
} else {
    Write-Host "Already in User PATH: $flutter_bin" -ForegroundColor Yellow
}

# refresh la session 
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host ""
Write-Host "Flutter is ready. Try:" -ForegroundColor Cyan
Write-Host "  flutter --version" -ForegroundColor Cyan