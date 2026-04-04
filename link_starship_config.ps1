
if (Test-Path ~/.config/starship.toml) {
    Remove-Item ~/.config/starship.toml -Force
}
New-Item -ItemType HardLink -Path ~/.config/starship.toml -Target starship.toml

$sourcePath = (Resolve-Path starship.toml).Path -replace '\\', '/'
wsl -- ln -sfv "`$(wslpath $sourcePath)" ~/.config/starship.toml