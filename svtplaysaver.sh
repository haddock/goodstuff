#!/bin/bash

NUM_ARGS=1 

function get_playlist {
    URL=$1
    if [[ ! $URL =~ ^http://svtplay.se/* ]]
    then
        echo "Felaktig URL!"
        exit 1
    fi

    SRC=$( curl -# $URL | grep "m3u8" | tr -d '"' )
    SRC=${SRC##*src=}
    SRC=${SRC%%poster=*}
}

function strip_basename {
    URL=$1
    URL_HOSTPATH=${URL%/*}
}

function get_files_from_playlist {
    FILES_LIST=$( curl -# $URL | tail -1 | tr -d '\015' )
    TS_FILES=( $( curl -# $URL_HOSTPATH/$FILES_LIST ) )

    COUNTER=0
    for I in ${TS_FILES[*]}
    do
        if [[ ! $I =~ ^# ]]
        then
            TS_FILES[$COUNTER]=$URL_HOSTPATH/$I
        else
            unset TS_FILES[$COUNTER]
        fi
        let COUNTER++
    done
}

function download_segments {
    if [ $# -eq 0 ]
    then
        SAVE_AS=${URL##*/}
        SAVE_AS=${SAVE_AS%.*}.ts
    else
        SAVE_AS=$1
    fi

    if [ -e $SAVE_AS ]
    then
        echo "Filen $SAVE_AS existerar redan! Avbryter!"
        exit 1
    fi
    COUNTER=1
    for I in ${TS_FILES[*]}
    do
        echo -e "\033[2J\033[4;0HSparar till $SAVE_AS\033[0;0HLaddar ner fil nummer $COUNTER (av ${#TS_FILES[*]}, $(( ($COUNTER-1) * 100 / ${#TS_FILES[*]} ))%)..."
        FILE_LIST=$( curl -# $I >> $SAVE_AS )
        let COUNTER++
    done
}

if [ $# -lt $NUM_ARGS ]
then
    NAME=$0
    cat <<END
END
else
    get_playlist $1
    strip_basename $SRC
    get_files_from_playlist
    if [ $# -eq 2 ]
    then
        download_segments $2
    else
        download_segments
    fi
fi

exit 0