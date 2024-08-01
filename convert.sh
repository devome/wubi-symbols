#!/usr/bin/env bash

export LANG=zh_CN.UTF-8
wubi_vers=( wb86 wb98 wbnewage )

## 检测imewlconverter和dos2unix
if ! type imewlconverter &>/dev/null; then
    echo "请先安装 imewlconverter: https://github.com/studyzy/imewlconverter"
    exit 1
fi

if ! type dos2unix &>/dev/null; then
    echo "请先安装 dos2unix"
    exit 1
fi

## 把symbol中的汉语词组提取为词组
awk -F '\t' '{print $3}' symbols/*.tsv | sed -E 's| |\n|g' | sort -u | grep -viP "[a-z]+" > dict-symbols.txt

## 转换为五笔键码
mkdir -p output
for ver in ${wubi_vers[@]}; do
    imewlconverter -i:word dict-symbols.txt -o:$ver "output/$ver.txt"
    dos2unix "output/$ver.txt"
done

## 把symbol符号也生成对应的键码
while read line; do
    symbol=$(echo "$line" | awk -F '\t' '{print $2}')
    regex=$(echo "$line" | awk -F '\t' '{print $3}' | sed -E 's/ /\|/g')

    for ver in ${wubi_vers[@]}; do
        keysyms=( $(grep -P "^[a-z]{1,4} ($regex)$" "output/$ver.txt" | awk '{print $1}' | sort -u) )
        for keysym in ${keysyms[@]}; do
            echo "$keysym $symbol" >> "output/$ver.txt"
        done

        keycodes=( $(echo "$line" | awk -F '\t' '{print $3}' | grep -oP '[a-z]+') )
        for keycode in ${keycodes[@]}; do
            echo "$keycode $symbol" >> "output/$ver.txt"
        done
    done
done <<< "$(cat symbols/*.tsv)"
