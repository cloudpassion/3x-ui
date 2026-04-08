#!/bin/bash

short_list=""
uuid_list=""

#for i in $(seq 1 300); do
for i in $(seq 1 10); do

    u=$(uuid 2>/dev/null)
    if [ ! $u ]; then
        u=$(uuidgen)
    fi

    while [ 1 -eq 1 ]; do

        echo u:$u

        short=$(echo $u | rev | cut -d'-' -f1 | rev)
        echo sh:$short

        echo "$short_list" | grep $short > /dev/null
        if [ $? -eq 0 ]; then
            continue
        fi
        
        if [[ "$short_list" ]]; then
            short_list=$(echo -e "$short_list\n$short")
        else
            short_list=$short
        fi

        if [[ "$uuid_list" ]]; then
            uuid_list=$(echo -e "$uuid_list\n$u")
        else
            uuid_list=$u
        fi
        
        break

   done
    
done

echo "$uuid_list" > uuid.list.txt
echo "$short_list" > short.list.txt
