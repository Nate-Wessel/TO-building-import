# this script takes a set of points and does a centroidal voronoi 
# tesselation weighted by those points from an initial uniform 
# random seeding. The effect is an even-ish distribution of sample 
# points accross the space.

library('deldir')	# voronoi stuff
library('rgdal')	# projections
library('sp') # spatial data types

# SET SOME GLOBAL VARIABLES
INPUT_FILE = '~/centroids.csv'
OUTPUT_FILE = '~/centers.csv'
FROM_EPSG = CRS('+init=epsg:4326')
TO_EPSG = CRS('+init=epsg:4326')
MAX_ITER = 75
NUM_SEED_POINTS = 300

# function copied from http://carsonfarmer.com/2009/09/voronoi-polygons-with-r/
voronoipolygons = function(layer,bounding_box) {
    crds = layer@coords
    z = deldir(crds[,1], crds[,2],rw=bounding_box)
    w = tile.list(z)
    polys = vector(mode='list', length=length(w))
    for (i in seq(along=polys)) {
        pcrds = cbind(w[[i]]$x, w[[i]]$y)
        pcrds = rbind(pcrds, pcrds[1,])
        polys[[i]] = Polygons(list(Polygon(pcrds)), ID=as.character(i))
    }
    SP = SpatialPolygons(polys,proj4string=TO_EPSG)
    voronoi = SpatialPolygonsDataFrame(SP, data=data.frame(x=crds[,1], 
        y=crds[,2], row.names=sapply(slot(SP, 'polygons'), 
        function(x) slot(x, 'ID'))))
}

# get points from theh input file
inPoints = read.csv(INPUT_FILE)
# interpret as spatial data
coordinates(inPoints) <- c('lon','lat')
proj4string(inPoints) <- FROM_EPSG
# reproject to local UTM
inPoints <- spTransform(inPoints,TO_EPSG)
inPoints$x = coordinates(inPoints)[,1]
inPoints$y = coordinates(inPoints)[,2]

# define a reasonable, simple, bounding box for the polygon to be tesselated
xmin = min(inPoints$x) - 1000 # meters
xmax = max(inPoints$x) + 1000
ymin = min(inPoints$y) - 1000
ymax = max(inPoints$y) + 1000
boundingBox = c(xmin,xmax,ymin,ymax)

# randomly select seed points
seed_points = inPoints[sample(nrow(inPoints),NUM_SEED_POINTS),c('x','y')]
# do the initial tesselation
tiles = voronoipolygons(seed_points,boundingBox)
# iterate voronoi calculation with new centroids
for(i in 1:MAX_ITER){
	# if past the first iteration,
	prev_points = seed_points
	# calculate new centroids weighted by the bus stop locations
	meanxy = over(tiles,inPoints[,c('x','y')],fn=mean) # unweighted centroid of points in tile
	# eliminate zones/points with no stops (zero weight)
	meanxy = meanxy[!is.na(meanxy$x),]
	# spatialize the points
	seed_points = SpatialPoints(meanxy)
	# check for convergence
	if ( length(prev_points) == length(seed_points) ) {
		if ( all(prev_points$x==seed_points$x) & all(prev_points$y==seed_points$y) ) {
			print('convergence achieved')
			break		
		}
	}
	# not converged so print status
	print(paste(length(seed_points),'points on iter',i))
	# calculate new tiles
	tiles = voronoipolygons(seed_points,boundingBox)
	# plot iterations?
	png(paste0('~/temp/',i,'.png'),width=1000,height=800)
		par(mar=rep(1, 4))
		# plot tiles
		plot(tiles, axes=FALSE, ann=FALSE,border=rgb(0,0,0,0.5))
		# plot bus stops
		points(inPoints,pch=20,col=rgb(1,0,0,0.3),cex=0.5)
		# plot points
		points(seed_points,pch=20,col='black')
	dev.off()
}
# get lat,lons along with projected x,y
proj4string(seed_points) <- TO_EPSG
unprojected <- spTransform(seed_points,FROM_EPSG)
seed_points$lon = coordinates(unprojected)[,1]
seed_points$lat = coordinates(unprojected)[,2]
#output to CSV
write.csv(seed_points,OUTPUT_FILE)
# output polygons to geojson
writeOGR(tiles,'out.geojson',driver='GeoJSON',layer='layername')