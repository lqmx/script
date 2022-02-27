#!/bin/bash

while read -r line
do
    arr=(${line//=/ })
    if [[ ${#arr[@]} == 2 ]];
    then
        scriptName=${arr[0]}
        version=${arr[1]}
        if [[ -f "$scriptName$version.sh" ]];
        then
            cp -r $scriptName$version.sh lastest/$scriptName.sh
            sed -i '' "s/^version=.*/version='$version'/g" lastest/$scriptName.sh
        else
            echo "File not found: $scriptName$version.sh"
            continue
        fi
    else
        echo "error: ${line}"
        continue
    fi
done < "version.txt"
