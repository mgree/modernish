#! /usr/bin/env modernish

let x=0
while test $x -lt 1000000; do
	x=$((x+1))
done
echo $x
