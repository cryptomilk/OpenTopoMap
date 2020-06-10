# Reduced Garmin maps

This creates a set of garmin maps with reduced information. This is meant to
run on low end devices such as smart watches and fitness trackers (e.g. fenix).

## Building a custom Garmin map - a complete walkthrough

Based on the [HOWTO](HOWTO) this guide describes how to create a custom Garmin map.
using OpenTopoMap styles.

### Required tools & OpenTopoMap repository

```bash
git clone https://github.com/der-stefan/OpenTopoMap.git
cd OpenTopoMap/garmin
```

Download [mkgmap](http://www.mkgmap.org.uk/download/mkgmap.html),
[splitter](http://www.mkgmap.org.uk/download/splitter.html) & bounds

```bash
MKGMAP="mkgmap-r4136" SPLITTER="splitter-r591" ./tools/get_bounds.sh
```

### Fetch map data, split & build garmin map

```bash
mkdir data
pushd data > /dev/null

rm -f morocco-latest.osm.pbf
wget "https://download.geofabrik.de/africa/morocco-latest.osm.pbf"

rm -f 6324*.pbf
java -jar $SPLITTERJAR --precomp-sea=$SEA "$(pwd)/morocco-latest.osm.pbf"
DATA="$(pwd)/6324*.pbf"

popd > /dev/null

OPTIONS="$(pwd)/opentopomap_options"
STYLEFILE="$(pwd)/style/opentopomap"

pushd style/typ > /dev/null

java -jar $MKGMAPJAR --family-id=35 OpenTopoMap.txt
TYPFILE="$(pwd)/OpenTopoMap.typ"

popd > /dev/null

java -jar $MKGMAPJAR -c $OPTIONS --style-file=$STYLEFILE \
    --precomp-sea=$SEA \
    --output-dir=output --bounds=$BOUNDS $DATA $TYPFILE

# optional: give map a useful name:
mv output/gmapsupp.img output/morocco.img

```
