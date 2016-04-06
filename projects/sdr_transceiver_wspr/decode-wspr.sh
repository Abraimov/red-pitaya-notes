#! /bin/sh

# CALL and GRID should be specified to enable uploads
CALL=
GRID=

JOBS=2
NICE=10

RECORDER=/root/write-c2-files
CONFIG=/root/write-c2-files.cfg

DECODER=/root/wsprd/wsprd
ALLMEPT=ALL_WSPR.TXT

date

echo "Sleeping ..."

SECONDS=`date +%S`
sleep `expr 60 - $SECONDS`

date
TIMESTAMP=`date --utc +'%y%m%d_%H%M'`

echo "Recording ..."

killall -v $RECORDER
$RECORDER $CONFIG

echo "Decoding ..."

parallel --jobs $JOBS --nice $NICE $DECODER -JC 5000 ::: wspr_*_$TIMESTAMP.c2
rm -f wspr_*_$TIMESTAMP.c2

test -n "$CALL" -a -n "$GRID" -a -s $ALLMEPT || exit

echo "Uploading ..."

sort -n -k 1,1 -k 2,2 -k 6,6 -o $ALLMEPT < $ALLMEPT
curl -sS -m 8 -F allmept=@$ALLMEPT -F call=$CALL -F grid=$GRID http://wsprnet.org/post > /dev/null

test $? -ne 0 || rm -f $ALLMEPT
