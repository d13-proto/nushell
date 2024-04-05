#! /usr/bin/env nu

use starship.nu
use themes/google-light.nu

source alias.nu
source function.nu

# 更新 Nushell 配置
def upgrade-nu-config [] {
    let configPath = $nu.config-path | path dirname
    let configFile = $configPath | path join config.nu
    let oldVersion = (
        open $configFile
        | parse -r 'version = "([\d\.]+)"'
        | get capture0.0
    )
    if ($oldVersion | is-empty) {
        error make {msg: '无法获取旧版本号'}
    }
    let configFileOld = $configPath | path join old_versions $"config-($oldVersion).nu"
    let envFile = $configPath | path join env.nu
    let envFileOld = $configPath | path join old_versions $"env-($oldVersion).nu"

    print '备份旧版本配置'
    mv -f $configFile $configFileOld
    mv -f $envFile $envFileOld

    print '生成当前版本配置'
    config reset --without-backup

    print '注入用户配置'
    $"\nsource ($configPath | path join config.user.nu)" | save -a $configFile

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
