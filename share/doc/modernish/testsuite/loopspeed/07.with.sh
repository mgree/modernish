#! /usr/bin/env modernish
use loop/with

with x=0 to 999999; do
	:
done
echo $x
