#!/bin/bash
# Copyright (c) 2020     Andreas Schneider <asn@cryptomilk.org>
# Licence: GPL

cleanup_and_exit () {
    if test "$1" = 0 -o -z "$1" ; then
        exit 0
    else
        exit $1
    fi
}

# Remove temporary pbf files on "ctrl+c"
cleanup_data() {
    if [ -w "$continent_tmp_pbf" ]; then
        rm -f "$continent_tmp_pbf"
    fi
    cleanup_and_exit 1
}
trap cleanup_data SIGINT

function usage () {
    echo "Usage: `basename $0` --out-dir=PATH --osm-data-dir=PATH [--continents=CONTINENTS"
    exit 0
}

function make_help () {
    echo
    cat << EOF
    --out-dir=PATH          The path used to build the maps
    --osm-data-dir=PATH     The path to find the osm-data (bound, sea, poly, etc)
    --continents=CONTINENTS Define the contients to build e.g. "africa europe"
EOF
}

while test -n "$1"; do
    PARAM="$1"
    ARG="$2"
    shift
    case ${PARAM} in
        *-*=*)
        ARG=${PARAM#*=}
        PARAM=${PARAM%%=*}
        set -- "----noarg=${PARAM}" "$@"
    esac
    case ${PARAM} in
      *-help|-h)
          usage
          make_help
          cleanup_and_exit
      ;;
      *-out-dir)
          _outdir="${ARG}"
          shift
      ;;
      *-osm-data-dir)
          _osmdatadir="${ARG}"
          shift
      ;;
      *-continents)
          continents="${ARG}"
          shift
      ;;
      ----noarg)
          echo "$ARG does not take an argument"
          cleanup_and_exit
      ;;
      --)
          additional_opts="$@"
          while test -n "$1"; do
              shift
          done
      ;;
      -*)
          echo Unknown Option "$PARAM". Exit.
          cleanup_and_exit 1
      ;;
      *)
          usage
      ;;
    esac
done

if [ "x$_outdir" = "x" ]; then
    usage
    cleanup_and_exit
fi
eval _outdir="$_outdir"
mkdir -p $_outdir

# Cleanup tmp dir if it exists
rm -rf "$_outdir/tmp"

if [ "x$_osmdatadir" = "x" ]; then
    usage
    cleanup_and_exit
fi

eval _continentdatadir="$_osmdatadir/continents"
if [ ! -d "$_continentdatadir" ]; then
    mkdir -p "$_continentdatadir"
fi

eval _osmdatadir=$_osmdatadir

_bounds_dir="$_osmdatadir/bounds"
if [ ! -d "$_bounds_dir" ]; then
    echo "Couldn't find bounds dir: $_bounds_dir"
    cleanup_and_exit 1
fi

_sea_dir="$_osmdatadir/sea"
if [ ! -d "$_sea_dir" ]; then
    echo "Couldn't find sea dir: $_sea_dir"
    cleanup_and_exit 1
fi

# Get the current directory of the script
_script=$(readlink -f $0)

_otmtooldir=$(dirname $_script)
if [ ! -d "$_otmtooldir" ]; then
    echo "Couldn't find OpenTopoMap tool dir: $_otmtooldir"
    cleanup_and_exit 1
fi
_otmdir=$(dirname $_otmtooldir)

_tilesinpoly_cmd="$_otmtooldir/tiles_in_poly.py"
if [ ! -x "$_tilesinpoly_cmd" ]; then
    echo "Couldn't find script $_tilesinpoly_cmd"
    cleanup_and_exit 1
fi

# TODO generate typ file
_otmtypfile="$_otmdir/style/typ/OpenTopoMap.typ"
if [ ! -r "$_otmtypfile" ]; then
    echo "Couldn't find TYP file $_otmtypfile"
    cleanup_and_exit 1
fi

_otmstyle="$_otmdir/style/opentopomap"
_mkgmap_opts="$_otmdir/mkgmap_options"

_cpu_count=$(nproc --all)
_map_id=53530001

_continents="${continents:-africa antarctica asia australia-oceania central-america europe north-america south-america}"

for continent in $_continents; do
    _continentdir="$_continentdatadir/$continent"
    _continent_pbf="$_continentdir/$continent-latest.osm.pbf"

    mkdir -p "$_continentdir"
    if [ ! -r "$_continent_pbf" ]; then
        echo "Download continent $continent ..."

        continent_tmp_pbf=$(mktemp --tmpdir XXXXXXXX.pbf)
        wget -O $continent_tmp_pbf "http://download.geofabrik.de/$continent-latest.osm.pbf"
        mv "$continent_tmp_pbf" "$_continent_pbf"
    fi

    _continent_workdir="$_outdir/tmp/$continent"
    mkdir -p $_continent_workdir

    echo "Split $continent into tiles ..."

    MKGMAP_MEM="16G" \
    tilesplitter "$_continent_pbf" \
        --output-dir=$_continent_workdir \
        --max-threads=8 \
        --geonames-file=$_osmdatadir/cities/cities15000.txt \
        --mapid=$_map_id > $_continent_workdir/tilesplitter.log

    for polyfile in $_osmdatadir/poly/$continent/*.poly; do
        country=$(basename $polyfile)
        country=${country%.*}
        _countrydir="$_continent_workdir/$country"

        if [ "$country" != "germany" ]; then
            continue
        fi

        mkdir -p "$_countrydir"

        echo "Generate $country with polyfile $polyfile ..."

        _countrypbfs=$($_tilesinpoly_cmd $polyfile $_continent_workdir/areas.list)

        _mkgmap_input=""
        for p in $_countrypbfs; do
            _mkgmap_input="${_mkgmap_input}${_continent_workdir}/${p} "
        done

        echo "Generate map for $country ..."

        MKGMAP_MEM=16G \
        mkgmap \
            --output-dir=$_countrydir \
            --max-jobs=8 \
            --style-file=$_otmstyle \
            --description="OTM ${country^}" \
            --bounds=$_bounds_dir \
            --precomp-sea=$_sea_dir \
            -c $_mkgmap_opts \
            $_mkgmap_input \
            $_otmtypfile > $_countrydir/mkgmap.log

        mv $_countrydir/gmapsupp.img $_outdir/otm-$country.img
    done
done

cleanup_and_exit
