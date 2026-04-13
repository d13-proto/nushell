# Create hardlink for configuration file
if (Test-Path ~/.config/starship.toml) {
    Remove-Item ~/.config/starship.toml -Force
}
New-Item -ItemType HardLink -Path ~/.config/starship.toml -Target starship.toml

if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    # WSL exists, copy to WSL
    $sourcePath = (Resolve-Path starship.toml).Path -replace '\\', '/'
    wsl -- cp -v "`$(wslpath $sourcePath)" ~/.config/starship.toml
}