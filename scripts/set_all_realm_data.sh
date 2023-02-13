#!/bin/sh

for i in {0..159}
do 
    min=$((50*$i+1))
    max=$((50*($i+1)))
    nile set_realm_data $min-$max
done
