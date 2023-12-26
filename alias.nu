#! /usr/bin/env nu

# less 忽略大小写
$env.LESS = '-i'

alias ll = ls -al
alias cp = cp -i
alias df = df -h

def table-less [...args] {table -ew -1 | less -RS -FX $args}

# systemd
alias s = sudo systemctl

# Git
def --wrapped g [command: string='', ...args] {
    match $command {
        '' => {git status}
        a  => {git add $args}
        c  => {git commit $args}
        l  => {git log $args}
        _  => {git $command $args}
    }
}

# pacman
alias p = sudo pacman

# yay
def --wrapped y [command: string='', ...args] {
    match $command {
        '' => {proxychains yay --aur}
        u  => {proxychains yay -Syu --aur --nocleanmenu --nodiffmenu --noconfirm $args}
        i  => {sudo pacman -Sy $args}
        s  => {sudo pacman -Syu $args}
        r  => {sudo pacman -Rns $args}
        _  => {proxychains yay --aur $command $args}
    }
}

# Homestead
def --wrapped h [command: string='', ...args] {
    cd ~/.local/homestead

    match $command {
        '' => {vagrant status}
        r  => {
            rm -f after.sh
            rm -f aliases
            bash init.sh
            vagrant reload --provision $args
        }
        s  => {vagrant suspend $args}
        _  => {vagrant $command $args}
    }
}

alias tldr = proxychains tldr

alias yt-dlp = yt-dlp --proxy=socks5://127.0.0.1:7890

def --wrapped yd [...args] {
    yt-dlp -F $args | print

    let format = input 'Format[bv+ba]: ' | match $in {'' => 'bv+ba', _ => $in}

    yt-dlp -f $format $args
}
