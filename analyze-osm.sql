-- look into simplification issues in existing OSM buildings
ALTER TABLE tobuild_polygon 
	ADD COLUMN orig_node_count int,
	ADD COLUMN simp_node_count int,
	ADD COLUMN centroid geometry(point,4326);

UPDATE tobuild_polygon SET 
	centroid = ST_Centroid(way),
	orig_node_count = ST_NPoints(way),
	simp_node_count = ST_Npoints( ST_Simplify( ST_Transform(way,32617), 0.15) );
