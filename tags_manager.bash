#!/usr/bin/env bash


tagdir=~/.vim/.tags
paths=filepaths.txt

# Colors for `echo` {{{
WARNING_COLOR="1;31"
SELECTED_COLOR="1;32"
HINT_COLOR="1;33"
TIME_COLOR="0;30;46"
COLOR_END="0"
# }}}

# Parse parameters {{{
while getopts "h r n a u l c: d:" option
do
    case $option in
        h)
            helpdoc=true;;
        r)
            reset=true;;
        n)
            new=true;;
        a)
            add=true;;
        u)
            update=true;;
        l)
            list=true;;
        c)
            change=$OPTARG;;
        d)
            delete=$OPTARG;;
        *)
            echo -e "\033[${WARNING_COLOR}m" \
                There are some errors in arguments. See help: \
                "\033[${COLOR_END}m"
            helpdoc=true;;
    esac
done
# }}}

# Goto Help. {{{
if [[ -z $* ]]
then
    helpdoc=true
fi
# }}}

# Help {{{
if [[ -n $helpdoc ]]
then
    echo " usage: tagsmgr [-h] [-n] [-l] [-c <TAG>] [-d <TAG>]"
    echo "                [-r] [-a] [-u]"
    echo -e "\033[${HINT_COLOR}m" \
        "-h      " \
        "\033[${COLOR_END}m" \
        Show the help.
    echo -e "\033[${HINT_COLOR}m" \
        "-n      " \
        "\033[${COLOR_END}m" \
        Creat a new tag in current directory.
    echo -e "\033[${HINT_COLOR}m" \
        "-l      " \
        "\033[${COLOR_END}m" \
        Show the list of existed tags.
    echo -e "\033[${HINT_COLOR}m" \
        "-c <TAG>" \
        "\033[${COLOR_END}m" \
        Change the default tag to \<TAG\>
    echo -e "\033[${HINT_COLOR}m" \
        "-d <TAG>" \
        "\033[${COLOR_END}m" \
        Delete the tag named \<TAG\>
    echo -e "\033[${HINT_COLOR}m" \
        "-r      " \
        "\033[${COLOR_END}m" \
        Reset \(clear\) all the tags.
    echo -e "\033[${HINT_COLOR}m" \
        "-a      " \
        "\033[${COLOR_END}m" \
        Add current directory to $paths .
    echo -e "\033[${HINT_COLOR}m" \
        "-u      " \
        "\033[${COLOR_END}m" \
        Update the default tags by $paths .
    exit -1
fi
# }}}

# Check directory {{{
if [[ ! ( -d $tagdir ) ]]
then
    mkdir -p $tagdir
fi
# }}}

# Reset {{{
if [[ -n $reset ]]
then
    rm -rf $tagdir
    mkdir -p $tagdir
    exit 0
fi
# }}}

# Record the time of start {{{
if [[ -n $new$update ]]
then
    DATE=$(date)
    START=$(date +%s)
fi
# }}}

# Move current tags to backup if needed {{{
if [[ -n $new$change ]]
then
    if [[ (  -n $new && -f $tagdir/tagname ) \
        || ( -n $change && -d $tagdir/$change ) ]]
    then
        if ( test -s $tagdir/tagname )
        then
            name=$(cat $tagdir/tagname)
            mkdir -p $tagdir/$name
            mv $tagdir/cscope.* $tagdir/$name
            mv $tagdir/*.txt $tagdir/$name
            mv $tagdir/tag* $tagdir/$name
            echo Default -\> $tagdir/$name
        fi
    fi
fi
# }}}

# Move specified tag to default if needed {{{
if [[ -n $change ]]
then
    if [[ -d $tagdir/$change ]]
    then
        mv $tagdir/$change/* $tagdir/
        rmdir $tagdir/$change
        echo $tagdir/$name -\> Default
    else
        echo -e "\033[${WARNING_COLOR}m" \
            " The tag <$change> not found!" \
            "\033[${COLOR_END}m"
        exit -2
    fi
fi
# }}}

# Make `filepaths.txt` {{{
if [[ -n $new$add ]]
then
    find $PWD -name '*.java' \
        -or -name '*.aidl' \
        -or -name '*.c' \
        -or -name '*.h' \
        -or -name '*.cpp' \
        >> $tagdir/$paths
    if test -s $tagdir/$paths
    then
        echo $tagdir/$paths Done.
    fi
fi
# }}}

# Generate tags of `ctags` and `cscope` {{{
if [[ -n $new$update ]]
then
    # Check filepaths.txt is not empty
    if [[ ! ( -f $tagdir/$paths ) ]]
    then
        echo -e "\033[${WARNING_COLOR}m" \
            $paths not found! \
            "\033[${COLOR_END}m"
        exit -3
    elif ! ( test -s $tagdir/$paths )
    then
        echo -e "\033[${WARNING_COLOR}m" \
            $paths is empty! \
            "\033[${COLOR_END}m"
        exit -4
    fi

    # Make tags
    ctags -L $tagdir/$paths -f $tagdir/tags
    echo ctags file is created.
    cscope -vRbkq -i $tagdir/$paths -f $tagdir/cscope.out
    echo cscope files are created.

    # Store current directory name as default tag name in file
    echo ${PWD##*/} > $tagdir/tagname

    # Display duration and date
    time=$(($(date +%s) - $START))
    echo -e "\033[${TIME_COLOR}m"
    echo "Begin: $DATE"
    echo "End  : $(date)"
    echo -e "Duration:" \
        $(($time / 3600)) h \
        $(($time / 60 % 3600)) m \
        $(($time % 60)) s \
        "\033[${COLOR_END}m"
fi
# }}}

# Delete the specified tag {{{
if [[ -n $delete ]]
then
    for name in $(ls $tagdir)
    do
        if [[ $name == $delete ]]
        then
            rm -rf $tagdir/$delete/
            break
        fi
    done
fi
# }}}

# Display current tags' list {{{
if [[ -n $new$list$change ]]
then
    if [[ -f $tagdir/tagname ]]
    then
        echo -e "*""\033[${SELECTED_COLOR}m" \
            $(cat $tagdir/tagname) \
            "\033[${COLOR_END}m"
    else
        echo "*"
    fi
    for name in $(ls $tagdir)
    do
        [ -d $tagdir/$name ] && echo "  "$name
    done
fi
# }}}

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:
