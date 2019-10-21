ALTER TABLE odb_ontario ADD COLUMN conflated boolean default false;

UPDATE odb_ontario SET conflated = FALSE WHERE conflated = TRUE;
UPDATE odb_ontario AS b SET conflated = TRUE 
FROM tobuild_polygon AS osm
	WHERE csdname = 'Toronto' -- just in Toronto
	AND ST_Intersects(b.geom,osm.way)
	AND osm.building IS NOT NULL and osm.building != 'no';