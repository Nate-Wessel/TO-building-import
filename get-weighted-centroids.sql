COPY (
	SELECT 
		ST_X(ST_Transform(centroid,3857)) as x,
		ST_Y(ST_Transform(centroid,3857)) AS y,
		orig_node_count - simp_node_count AS w
	FROM tobuild_polygon
	WHERE orig_node_count - simp_node_count > 0
) TO '/home/nate/scripts/to-build-import/weighted-centroids.csv' CSV HEADER;