# get buildings data
wget -O buildings.osm --post-file=overpass/buildings.txt https://overpass-api.de/api/interpreter
# populate database
osm2pgsql --slim --hstore-all -x --prefix tobuild --proj 4326 --style building.style -d osm buildings.osm
# add/update stuff
psql -d osm -f analyze-osm.sql
