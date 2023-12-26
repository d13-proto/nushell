#! /usr/bin/env nu

use starship.nu
use themes/google-light.nu

source alias.nu
source function.nu

# 更新 Nushell 配置版本
def upgrade-nu-config [] {
    let configPath = $nu.config-path | path dirname
    let version = (
        open $"($configPath)/config.nu"
        | parse -r 'version = "([\d\.]+)"'
        | get capture0.0
    )

    # 备份旧版本配置
    mv -v $"($configPath)/config.nu" $"($configPath)/old_versions/config-($version).nu"
    mv -v $"($configPath)/env.nu" $"($configPath)/old_versions/env-($version).nu"

    # 生成新版本配置
    config reset --without-backup

    # 注入用户配置
    $"\nsource ($configPath)/config.user.nu" | save -a $"($configPath)/config.nu"

    # 顺便更新 Starship 配置
    starship init nu | save -f starship.nu
}

# Fish 自动完成
let fish_completer = {
	|spans|
	# if the current command is an alias, get it's expansion
	let expanded_alias = (scope aliases | where name == $spans.0 | get -i 0 | get -i expansion)

	# overwrite
	let spans = (if $expanded_alias != null  {
		# put the first word of the expanded alias first in the span
		$spans | skip 1 | prepend ($expanded_alias | split words)
	} else { $spans })

	fish --command $'complete "--do-complete=($spans | str join " ")"'
	| $"value(char tab)description(char newline)" + $in
	| from tsv --flexible --no-infer
}
# https://www.nushell.sh/cookbook/external_completers.html

# 主题
let theme = (google-light | merge-deep {
    separator: "black_dimmed"
})
# https://www.nushell.sh/book/coloring_and_theming.html

# 修改快捷键
let $keybindings = ($env.config.keybindings | each {
    match $in.name {
        cut_word_left => {merge {keycode: char_h}}
        _ => $in
    }
})

# 合并配置
$env.config = ($env.config | merge-deep {
    show_banner: false

    rm: {
        always_trash: true
    }

    table: {
        mode: compact
        padding: { left: 0, right: 0 }
    }

    history: {
        sync_on_enter: false    
    }

    completions: {
        external: {
            completer: $fish_completer
        }
    }

    color_config: $theme

    keybindings: $keybindings
})
