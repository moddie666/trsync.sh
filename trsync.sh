#!/bin/bash
# CREATE A FILE CALLED "TNUM" AT THE LOCATION YOU'RE RUNNING FROM
# TO ADJUST THREADCOUNT FOR THIS SCRIPT. (E.G. echo -n "25" > TNUM)


SOURCE="$1"
TARGET="$2"
DIRS="/dirA/dirB /dirA/dirZ /dirQ"
RSOPT="-lravxh"
RSGRP="time.*rsync.*$RSOPT"
ITER=0

SYNCS=$(
        ssh $SOURCE find /dirA/dirB -maxdepth 2 -type d | sort -rn | grep -v '^/dirA/dirC$'
        ssh $SOURCE find /dirD/dirE -maxdepth 1 -type d | sort -rn 
        ssh $SOURCE find /dirF -maxdepth 1 -type d | sort -rn 
)
QLEN=$(wc -l <<< "$SYNCS")

count_rsync(){
        pgrep -f "time.*rsync.*$RSOPT.*"|wc -l
}
tadjust(){
        WID=$(tput cols)
        DIS=$((WID - 5))
        #HEI=$(tput lines)
        TNUM="$(egrep -o "[0-9]+" TNUM 2>/dev/null)"
        if [ "x$TNUM" = "x" ] # IF TNUM WAS EMPTY DEFAULT TO 10
        then TNUM="10" ;fi
        OUTPUT="T:[$SECONDS]:R[$ITER/$QLEN]W:[$RNUM/$TNUM]:{$(echo $(ps auxww | grep "$RSGRP" | grep -v "grep.*rsync" | egrep -o '[^ /]+$'))}"
        LEN=$(echo -n "$OUTPUT"|wc -c)
        if [ "$LEN" -gt "$DIS" ]
        then OUTPUT="$(cut -c -$DIS <<< "$OUTPUT") ..."
        fi
        echo -e -n "\r$OUTPUT\033[K"
}

run_item(){
        2>&1 mkdir -pv $TARGET$item
        2>&1 time rsync $RSOPT --delete $SOURCE:$item/ $TARGET$item
        echo "DONE: [$SOURCE:$item/] -> [$TARGET$item]"
}
for item in $SYNCS / 
do
        ((ITER++))
        tadjust
        run_item >> frsync.log &
        RNUM=$(count_rsync)
        while [ "$RNUM" -ge "$TNUM" ]
        do
                RNUM=$(count_rsync)
                tadjust
                #sleep 0.1
        done
done
while [ "$RNUM" -ne 0 ]
do
        RNUM=$(count_rsync)
        OUTPUT="Workers left: $RNUM : $(echo $(ps auxww | grep "$RSGRP"|grep -v "grep.*rsync" | egrep -o '[^ /]+$'))"
        echo -e -n "\r$OUTPUT\033[K"
done
echo "ran $SECONDS seconds"
