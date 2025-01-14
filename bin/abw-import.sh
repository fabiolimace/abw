#!/bin/bash
#
# Usage:
#
#    abw-import INPUT_FILE [FILE...]
#    abw-import -r DIRECTORY [DIRECTORY...]
#    abw-import -r -c COLLECTION DIRECTORY [...]
#

OPTSTRING="ic:idrvh"
source `dirname $0`/abw-common.sh


function create_directory {
    local DIRECTORY="${1}"
    mkdir --parents $DIRECTORY;
}

function create_database {

    local DATABASE="${1}"
    
    if [ -f "$DATABASE" ];
    then
        return;
    fi;
    
    sqlite3 "$DATABASE" <<EOF
CREATE TABLE text_ (uuid_ TEXT PRIMARY KEY, content_ TEXT) STRICT;
CREATE TABLE meta_ (uuid_ TEXT PRIMARY KEY, collection_ TEXT, hash_ TEXT, name_ TEXT, path_ TEXT, mime_ TEXT, date_ TEXT, lines_ INTEGER, words_ INTEGER, bytes_ INTEGER, chars_ INTEGER, CONSTRAINT meta_fk_ FOREIGN KEY (uuid_) REFERENCES text_ (uuid_))  STRICT;
CREATE TABLE data_ (uuid_ TEXT, token_ TEXT, type_ TEXT, count_ INTEGER, ratio_ REAL, format_ TEXT, case_ TEXT, length_ INTEGER, indexes_ TEXT, CONSTRAINT data_pk_ PRIMARY KEY (uuid_, token_), CONSTRAINT data_fk_ FOREIGN KEY (uuid_) REFERENCES text_ (uuid_))  STRICT;
EOF

}

function exists_text_fs {

    local COLLECTION="${1}"
    local UUID="${2}"
    
    local DIRECTORY=`directory "$COLLECTION" "$UUID"`
    
    if [ ! -d "$DIRECTORY" ];
    then
        return;
    fi;
    
    find "$DIRECTORY" -type f -name "text.txt" | wc -l;
}

function exists_text_db {

    local COLLECTION="${1}"
    local UUID="${2}"
    
    local DATABASE=`database $COLLECTION`
    
    if [ ! -f "$DATABASE" ];
    then
        return;
    fi;
    
    sqlite3 "$DATABASE" "select count(1) from text_ where uuid_ = '$UUID';";
}

function import_text_fs {

    local COLLECTION="${1}"
    local INPUT_FILE="${2}"
    local UUID="${3}"
    
    local DIRECTORY=`directory "$COLLECTION" "$UUID"`
    local OUTPUT_FILE="$DIRECTORY/text.txt"
    
    create_directory "$DIRECTORY";
    
    cp $INPUT_FILE $OUTPUT_FILE;
}

function import_text_db {
    
    local COLLECTION="${1}"
    local INPUT_FILE="${2}"
    local UUID="${3}"
    
    local DATABASE=`database $COLLECTION`
    
    create_database "$DATABASE"
    
    cat "$INPUT_FILE" | sed "s/'/''/g" | awk '{content=content $0} END{ printf "INSERT INTO text_ values '"('%s', '%s');"'", "'$UUID'", content }' | sqlite3 "$DATABASE"
}

function import_meta_fs {

    local COLLECTION="${1}"
    local INPUT_FILE="${2}"
    local UUID="${3}"
    local HASH="${4}"
    
    local NAME=`basename $INPUT_FILE`
    local ROAD=`realpath $INPUT_FILE` # alias for PATH
    local MIME=`file -bi $INPUT_FILE`
    local DATE=`date '+%F %T'`
    local COUNT=`wc -lwcm "$INPUT_FILE" | awk '{ printf "%d\t%d\t%d\t%d\n", $1, $2, $3, $4; }'`
    local LINES=`echo "$COUNT" | cut -f 1`
    local WORDS=`echo "$COUNT" | cut -f 2`
    local BYTES=`echo "$COUNT" | cut -f 3`
    local CHARS=`echo "$COUNT" | cut -f 4`
    
    local DIRECTORY=`directory "$COLLECTION" "$UUID"`
    local OUTPUT_FILE="$DIRECTORY/meta.txt"
    
    echo -n > $OUTPUT_FILE
    echo "uuid=$UUID" >> $OUTPUT_FILE
    echo "collection=$COLLECTION" >> $OUTPUT_FILE
    echo "hash=$HASH" >> $OUTPUT_FILE
    echo "name=$NAME" >> $OUTPUT_FILE
    echo "path=$ROAD" >> $OUTPUT_FILE # TODO: change to the relative path inside the collection
    echo "mime=$MIME" >> $OUTPUT_FILE
    echo "date=$DATE" >> $OUTPUT_FILE
    echo "lines=$LINES" >> $OUTPUT_FILE
    echo "words=$WORDS" >> $OUTPUT_FILE
    echo "bytes=$BYTES" >> $OUTPUT_FILE
    echo "chars=$CHARS" >> $OUTPUT_FILE
}

function import_meta_db {

    local COLLECTION="${1}"
    local INPUT_FILE="${2}"
    local UUID="${3}"
    local HASH="${4}"
    
    local NAME=`basename $INPUT_FILE`
    local ROAD=`realpath $INPUT_FILE`
    local MIME=`file -bi $INPUT_FILE`
    local DATE=`date '+%F %T'`
    local COUNT=`wc -lwcm "$INPUT_FILE" | awk '{ printf "%d\t%d\t%d\t%d\n", $1, $2, $3, $4; }'`
    local LINES=`echo "$COUNT" | cut -f 1`
    local WORDS=`echo "$COUNT" | cut -f 2`
    local BYTES=`echo "$COUNT" | cut -f 3`
    local CHARS=`echo "$COUNT" | cut -f 4`
    
    local DATABASE=`database $COLLECTION`
    
    NAME=${NAME//\'/\'\'}; # escape quotes for SQLite
    ROAD=${ROAD//\'/\'\'}; # escape quotes for SQLite
    sqlite3 "$DATABASE" "INSERT INTO meta_ values ('$UUID', '$COLLECTION', '$HASH', '$NAME', '$ROAD', '$MIME', '$DATE', '$LINES', '$WORDS', '$BYTES', '$CHARS');";
}

function import_data_fs {

    local COLLECTION="${1}"
    local INPUT_FILE="${2}"
    local UUID="${3}"
    
    local DIRECTORY=`directory "$COLLECTION" "$UUID"`
    local OUTPUT_FILE="$DIRECTORY/data.txt"
    
    $BASEDIR/abw-process.sh $INPUT_FILE > $OUTPUT_FILE
}

function import_data_db {

    local COLLECTION="${1}"
    local INPUT_FILE="${2}"
    local UUID="${3}"
    
    local DATABASE=`database $COLLECTION`

    # TODO: selected fields by options
    $BASEDIR/abw-process.sh $INPUT_FILE | sed "s/'/''/g" | awk 'BEGIN { printf "BEGIN DEFERRED TRANSACTION;\n"} NR > 1 { printf "INSERT INTO data_ values '"('$UUID', '%s', '%s', %d, %f, '%s', '%s', %d, '%s');\n"'", $1, $2, $3, $4, $5, $6, $7, $8, $9 } END {printf "COMMIT TRANSACTION;\n"}' | sqlite3 "$DATABASE"
}

function import_file {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    local IMPORT_TO_DATABASE=${options["d"]}
    
    if [[ ! -f "$INPUT_FILE" ]];
    then
        echo "abw-import.sh: $INPUT_FILE: File not found" 1>&2;
        return;
    fi;
    
    if [[ ! -s "$INPUT_FILE" ]];
    then
        echo "abw-import.sh: $INPUT_FILE: File is empty" 1>&2;
        return;
    fi;
    
    local HASH=`hash "$INPUT_FILE"`
    local UUID=`uuid "$HASH"`
    
    if [ "$IMPORT_TO_DATABASE" = 'd' ];
    then
    
        local EXISTS=`exists_text_db "$COLLECTION" "$UUID"`
        if [[ "$EXISTS" -gt 0 ]];
        then
            echo "abw-import.sh: $INPUT_FILE: Already imported" 1>&2;
            return;
        fi;
        
        import_text_db "$COLLECTION" "$INPUT_FILE" "$UUID"
        import_meta_db "$COLLECTION" "$INPUT_FILE" "$UUID" "$HASH"
        import_data_db "$COLLECTION" "$INPUT_FILE" "$UUID"
    else
    
        local EXISTS=`exists_text_fs "$COLLECTION" "$UUID"`
        if [[ "$EXISTS" -gt 0 ]];
        then
            echo "abw-import.sh: $INPUT_FILE: Already imported" 1>&2;
            return;
        fi;
        
        import_text_fs "$COLLECTION" "$INPUT_FILE" "$UUID"
        import_meta_fs "$COLLECTION" "$INPUT_FILE" "$UUID" "$HASH"
        import_data_fs "$COLLECTION" "$INPUT_FILE" "$UUID"
    fi;
    
    if [[ ${options["v"]} ]]; then
        echo "Imported '$INPUT_FILE'"
    fi;
}

function import_directory {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ ! -d "$INPUT_FILE" ]];
    then
        echo "abw-import.sh: $INPUT_FILE: Directory not found" 1>&2;
        return;
    fi;

    for i in `find "$INPUT_FILE" -type f -name "*.txt"`; do
        import_file "$COLLECTION" "$i";
    done;
}

function import_recursive {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ -f "$INPUT_FILE" ]]; then
        import_file "$COLLECTION" "$INPUT_FILE";
    elif [[ -d "$INPUT_FILE" ]]; then
        import_directory "$COLLECTION" "$INPUT_FILE";
    else
        echo "abw-import.sh: $INPUT_FILE: File or directory not found" 1>&2;
        return;
    fi;
}

while (( $# )) ; do

    INPUT_FILE=${1}
    COLLECTION=${options["c"]:=default}

    if [[ ${options["r"]} ]]; then
        import_recursive "$COLLECTION" "$INPUT_FILE";
    else
        import_file "$COLLECTION" "$INPUT_FILE";
    fi;

    shift;
done;

