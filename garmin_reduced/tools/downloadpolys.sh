#!/bin/bash

# (c) 2018-2019 OpenTopoMap under CC-BY-SA license
# author: Martin Schuetz, Stefan Erhardt
# A download script for the polygons of all countries worldwide

DATA_DIR=/home/asn/workspace/osm/osm-data/poly/

continents="europe"

for continent in $continents
do
    echo "Downloading poly files for $continent ..."

    wget --wait=0.1 \
        --no-parent \
        --recursive \
        --level 1 \
        --accept poly \
        http://download.geofabrik.de/$continent/ -P $DATA_DIR

    find $DATA_DIR -type d -delete 2>/dev/null
    mv $DATA_DIR/download.geofabrik.de/$continent $DATA_DIR
done

rm -rf download.geofabrik.de
