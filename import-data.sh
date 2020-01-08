# download data from https://www.statcan.gc.ca/eng/lode/databases/odb
# and unpack the shapefile. The data ill be imported into PostGIS
# for easier handling. Fill in the connection details below.

ogr2ogr -f PostgreSQL PG:"dbname='osm' host='localhost' user='' password=''" ODB_Ontario/odb_ontario.shp --config PG_USE_COPY YES -nlt MULTIPOLYGON
