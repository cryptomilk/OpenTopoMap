#!/bin/bash
# Copyright (c) 2020     Andreas Schneider <asn@cryptomilk.org>
# Licence: GPL

bounds_url="http://osm.thkukuk.de/data/bounds-latest.zip"
sea_url="http://osm.thkukuk.de/data/sea-latest.zip"
cities_url="http://download.geonames.org/export/dump/cities15000.zip"

cleanup_and_exit () {
    if test "$1" = 0 -o -z "$1" ; then
        exit 0
    else
        exit $1
    fi
}

# Remove zip files on "ctrl+c"
cleanup_data() {
    if [ -w "$bounds_zip" ]; then
        rm -f "$bounds_zip"
    fi

    if [ -w "$sea_zip" ]; then
        rm -f "$sea_zip"
    fi
    cleanup_and_exit 1
}
trap cleanup_data SIGINT

function usage () {
    echo "Usage: `basename $0` --out-dir=PATH [--update]"
    exit 0
}

function make_help () {
    echo
    cat << EOF
    --out-dir=PATH         The path to store the bounds and sea data
    --update               Update bounds and sea
EOF
}

do_update=0

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
      *-update)
          do_update=1
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

eval _datadir="$_outdir/osm-data"

if [ ! -d "$_datadir" ]; then
    mkdir -p "$_datadir"
fi

if [ $do_update -eq 1 ]; then
    rm -rf "$_data_dir/bounds"
    rm -rf "$_data_dir/sea"
    rm -rf "$_data_dir/cities"
fi

if [ ! -d "$_datadir/bounds" ]; then
    echo "Downloading bounds data"
    bounds_zip=$(mktemp --tmpdir XXXXXXXX.zip)
    wget -O $bounds_zip "$bounds_url"
    unzip -a $bounds_zip -d "$_datadir/bounds"
    rm -f $bounds_zip
else
    echo "Bounds data already downloaded"
fi

if [ ! -d "$_datadir/sea" ]; then
    echo "Downloading sea data"
    sea_zip=$(mktemp --tmpdir XXXXXXXX.zip)
    wget -O $sea_zip "$sea_url"
    unzip -a $sea_zip -d "$_datadir/sea_TMP"
    rm -f $sea_zip

    # Fix sea directory
    if [ -d "$_datadir/sea_TMP/sea" ]; then
        mv "$_datadir/sea_TMP/sea" "$_datadir/sea"
        rm -rf "$_datadir/sea_TMP"
    else
        mv "$_datadir/sea_TMP" "$_datadir/sea"
    fi
else
    echo "Sea data already downloaded"
fi

if [ ! -d "$_datadir/cities" ]; then
    echo "Downloading city data"
    city_zip=$(mktemp --tmpdir XXXXXXXX.zip)
    wget -O $city_zip "$cities_url"
    unzip -a $city_zip -d "$_datadir/cities"
    rm -f $city_zip
else
    echo "City data already downloaded"
fi

echo
echo "OSM DATA DIR: $_datadir"

cleanup_and_exit
