DROP TABLE IF EXISTS temptab;
CREATE TABLE temptab (
	x1 real,
	x2 real,
	y1 real,
	y2 real,
	depth int,
	num int
);
COPY temptab FROM '/home/nate/test.csv' CSV HEADER;

DROP TABLE IF EXISTS tempgrid;
SELECT 
	depth, 
	num AS num_nodes,
	ST_SetSRID( ST_MakePolygon( ST_MakeLine(
		ARRAY[ST_MakePoint(x1,y1),
		ST_MakePoint(x1,y2),
		ST_MakePoint(x2,y2),
		ST_MakePoint(x2,y1),
		ST_MakePoint(x1,y1)]
	) ), 3857)
INTO tempgrid
FROM temptab;
ALTER TABLE tempgrid ADD COLUMN uid serial primary key;