FILES=/home/nate/tasks/*.gpkg
for f in $FILES
do
	echo "Processing $f"
	python ~/scripts/ogr2osm/ogr2osm.py $f -t ~/scripts/to-build-import/ogr2osm_config.py
done
