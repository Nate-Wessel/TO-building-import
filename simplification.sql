-- look into simplification issues in existing OSM buildings

﻿ALTER TABLE tobuild_polygon 
	ADD COLUMN orig_node_count int,
	ADD COLUMN simp_node_count int;

ALTER TABLE tobuild_polygon ADD COLUMN centroid geometry(point,4326);
UPDATE tobuild_polygon SET centroid = ST_Centroid(way);

UPDATE tobuild_polygon SET 
	orig_node_count = ST_NPoints(way),
	simp_node_count = ST_Npoints( ST_Simplify( ST_Transform(way,32617), 0.15) );

/*
SELECT 
	SUM(orig_node_count) AS orig, 
	SUM(simp_node_count) AS simp,
	SUM(orig_node_count) - SUM(simp_node_count) AS surplus,
	(SUM(orig_node_count)-SUM(simp_node_count)) / SUM(orig_node_count)::real AS surplus_ratio
FROM tobuild_polygon;
*/
