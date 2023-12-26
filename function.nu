#! /usr/bin/env nu

# 视频修剪头尾
def video-trim [start: float, end: float=0., path: string='.'] {

    let files: list<string> = $in

    let pathExpanded: string = ($path | path expand)

    if not ($pathExpanded | path exists) {
        mkdir $pathExpanded
    }

    $files | par-each -kt 4 { |file|
        try {
            if ($file | path type) != file {
                error make {msg: $"不是文件: ($file)"}
            }

            # 计算结束时间
            let endOption: list<string>  = (if $end > 0 {
                let info: string = (
                    run ffprobe '-v' 'warning'
                    '-i' $file
                    '-show_format'
                )

                let duration: float = (
                    $info
                    | sed -n 's/duration=//p'
                    | default 0.
                    | into float
                )
                # `default 0.` 防止 into float 不支持空字符串

                ['-to', ($duration - $end)]

            } else {[]})

            let fileInfo = $file | path parse
            let output = $"($pathExpanded)/($fileInfo.stem)-trim.($fileInfo.extension)"

            (
                run ffmpeg '-v' 'warning' '-y'
                '-i' $file
                '-ss' $start
                $endOption
                '-c' 'copy'
                $output
            )

            return {input: $file, output: $output}

        } catch { |e|
            return {input: $file, error: $e.msg}
        }
    }
}

# 运行外部命令，返回码不为零时抛出错误
def --wrapped run [command: string='', ...args] {
    $in | (
        run-external --redirect-combine --trim-end-newline
        $command ($args | flatten)
        | complete
        | if $in.exit_code == 0 {
            $in.stdout
        } else error make -u {msg: $in.stdout}
    )
}

# 递归合并 record
def merge-deep [source: record] {

    let target: record = $in

    # 遍历源记录的项
    let source_all_merged: record = ($source | items {
        |key, value|

        let target_value = ($target | get -i $key)

        let value_merged = (
            if ($target_value | describe) starts-with record
                and ($value | describe) starts-with record {
                # 两个值都是记录
                # 递归合并
                $target_value | merge-deep $value
            } else {
                $value
            }
        )

        return {key: $key, value: $value_merged}

    } | transpose -rd | into record)
    # `into record` 防止 transpose 不把 empty list 转换成 record

    # 合并
    return ($target | merge $source_all_merged)
}
