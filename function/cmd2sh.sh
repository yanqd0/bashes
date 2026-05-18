# cmd2sh: Save commands to a file {{{
cmd2sh() {
    if [[ -n $2 ]]
    then
        num=$2
    else
        num=1
    fi

    if [[ -n $1 ]]
    then
        file=$1.sh
        if [[ -e $file ]]
        then
            echo "$file exists. Abort!"
            return
        fi

        echo "#!/usr/bin/env bash" > "$file"
        echo "" >> "$file"
        fc -nl | tail -$num \
            | sed "s/	 //g" \
            | sed "s/  *$//g" >> "$file"
        chmod +x "$file"
    else
        echo "Usage: cmd2sh <FILE_file> [<CMD_NUM>]"
    fi
}
# }}}
