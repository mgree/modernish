#! /usr/bin/env modernish
use loop/sfor

sfor 'x=0' 'lt x 1000000' 'inc x'; do
	:
done
echo $x
