-- odb_ontario data should have been imported into a table called...
ALTER TABLE odb_ontario 
	-- unprojected geometry
	ADD COLUMN geom geometry(MultiPolygon,4326),
	-- whether the building is potentially in the scope of this import
	ADD COLUMN in_scope boolean default FALSE,
	-- does this conflate to / conflict with an existing OSM building in the scope?
	ADD COLUMN conflated boolean default FALSE,
	-- local projected geometry
	ADD COLUMN loc_geom geometry(MultiPolygon,32617),
	-- number of nodes in the feature (to assess simplification)
	ADD COLUMN node_count smallint,
	-- number of nodes after simplification
	ADD COLUMN simp_node_count smallint,
	-- identifes building=part features - default false. 
	ADD COLUMN part boolean DEFAULT FALSE;

-- set unprojected and newly projected geometries
UPDATE odb_ontario SET 
	loc_geom = ST_Transform(wkb_geometry,32617),
	geom = ST_Transform(wkb_geometry,4326);

-- set the scope of this import to Toronto only
UPDATE odb_ontario SET in_scope = TRUE WHERE csdname = 'Toronto';

-- conflate in-scope portion of data with existing OSM buildings
UPDATE odb_ontario AS b SET conflated = TRUE 
FROM tobuild_polygon AS osm
WHERE 
	in_scope AND 
	ST_Intersects(b.geom,osm.way) AND 
	osm.building IS NOT NULL and osm.building != 'no';

/*
simplify in-scope, unconflated data while maintaining topology
15cm tolerance
Takes ~20 minutes to run
*/

-- dump e.g. interior rings
with poly as (
	SELECT
		uid, (st_dump(loc_geom)).* 
        FROM odb_ontario
        WHERE in_scope AND NOT conflated
) 
SELECT 
	poly.uid,
	ST_Transform(baz.geom,4326) AS geom -- unproject after simplification
INTO simplified_conflated_buildings
FROM ( 
        SELECT (ST_Dump(ST_Polygonize(distinct geom))).geom as geom
        FROM (
		-- simplify geometries to a 15cm tolerance to avoid repeated points
                SELECT (ST_Dump(st_simplifyPreserveTopology(ST_Linemerge(st_union(geom)), 0.15))).geom as geom
                FROM (
                        SELECT ST_ExteriorRing((ST_DumpRings(geom)).geom) as geom
                        FROM poly
                ) AS foo
        ) AS bar
) AS baz, poly
WHERE 
	ST_Intersects(poly.geom, baz.geom)
	AND ST_Area(st_intersection(poly.geom, baz.geom))/ST_Area(baz.geom) > 0.9;

ALTER TABLE simplified_conflated_buildings 
	ADD COLUMN 

-- add primary key for editing
ALTER TABLE simplified_conflated_buildings ADD COLUMN uid2 serial PRIMARY KEY;