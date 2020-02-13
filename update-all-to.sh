# get buildings data
wget -O all-to.osm --post-file=all-to-query.txt https://overpass-api.de/api/interpreter
# populate database
osm2pgsql --slim --hstore-all -x --prefix to --proj 4326 -d osm all-to.osm
