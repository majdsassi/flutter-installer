$release_uri = "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$release_response = Invoke-RestMethod -Uri $release_uri -Method Get -Headers @{"Accept" = "application/json"; "Content-Type" = "application/json"} ; 
$release_counter = -1 ; 
# check if the last release is stable and not beta 
do {
 $release_counter++ ;
 $last_release =  $release_response.releases[$release_counter]; 
}while($release_response.releases[$release_counter].channel -ne "stable") ;
# create the download url
$download_prefix = "https://storage.googleapis.com/flutter_infra_release/releases" ; 
$download_uri = -join($download_prefix,'/',$release_response.releases[$release_counter].archive.ToString()) ; 
$file_name = Join-Path -Path $env:TEMP -ChildPath "flutter.zip" ; 
Invoke-WebRequest -Uri $download_uri -OutFile $file_name ; 



