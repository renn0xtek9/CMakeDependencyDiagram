#!/bin/bash
SOURCE_FOLDER="$1"
DESTINATION_FOLDER="$2"

FILE_LIST_OF_TARGET_DIAGRAM="$DESTINATION_FOLDER/listOfTargetFileDependencyDiagrams.js"

echo "var targetDiagramFiles = [" > "$FILE_LIST_OF_TARGET_DIAGRAM"
first_target=true
while read -r filepath
do
    
    target_name=$(echo $(basename $filepath)|sed 's/cmake\.dot\.//g')

    dot -T png "$filepath" -o "$DESTINATION_FOLDER"/"$(basename "$filepath")".png

    if [ "$first_target" = true ]; then
        first_target=false
    else
        echo "," >> "$FILE_LIST_OF_TARGET_DIAGRAM"
    fi
    echo "'$target_name'" >> "$FILE_LIST_OF_TARGET_DIAGRAM"

done < <(find "$SOURCE_FOLDER" -name "*.dot*" |sort )


echo "];" >> "$FILE_LIST_OF_TARGET_DIAGRAM"
