#!/bin/bash

# (c) 2018-2019 OpenTopoMap under CC-BY-SA license
# author: Martin Schuetz, Stefan Erhardt
# A download script for the polygons of all countries worldwide

DATA_DIR=/home/asn/workspace/osm/poly/


dirs="europe"

for d in $dirs
do
	echo $d
	wget -w 0.1 -np -r -l 1 -A poly http://download.geofabrik.de/$d/ -P $DATA_DIR
done
