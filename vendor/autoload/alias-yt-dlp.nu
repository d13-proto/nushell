#! /usr/bin/env nu

def --wrapped yd [...args] {
    yt-dlp -F ...$args

    let format = input 'Format[bv+ba]: ' | match $in {'' => 'bv+ba', _ => $in}

    yt-dlp -f $format ...$args
}
