# script for recursively dividing a set of spatial points such that 
# points are collected in bounding boxes that are vaguelly sqare 
# an contain similar counts of weighted points 
library('tidyverse')
library('spatstat')

# read csv with numeric x,y,w values
d = read_csv('~/centroids.csv')
# maximum w per cell
maxweight = 250
results = tibble(
	x1=numeric(),x2=numeric(),
	y1=numeric(),y2=numeric(),
	depth=numeric(),count=numeric()
)

divide <- function(points,xrange,yrange,depth){
	# does this need to be divided? 
	if( sum(points$w) <= maxweight ){
		results <<- add_row(results,
			x1=xrange[1],x2=xrange[2],
			y1=yrange[1],y2=yrange[2],
			depth=depth,count=sum(points$w))
		return()
	}
	# find the longest dimension to divide
	divdim = if( diff(xrange) > diff(yrange) ) 'x' else 'y'
	# divide at the weighted median of that dimension
	slice = weighted.median(points[[divdim]],points$w)
	# tell what is happening
	print(paste('dividing along',divdim,'at',slice,'recursion depth',depth))
	# define the halves and recurse
	p1 = points[points[[divdim]]<slice,]
	xrange1 = if(divdim=='y') xrange else c(xrange[1],slice)
	yrange1 = if(divdim=='x') yrange else c(yrange[1],slice)
	divide(p1,xrange1,yrange1,depth+1)
	
	p2 = points[points[[divdim]]>=slice,]
	xrange2 = if(divdim=='y') xrange else c(slice,xrange[2])
	yrange2 = if(divdim=='x') yrange else c(slice,yrange[2])
	divide(p2,xrange2,yrange2,depth+1)
}
# initial call of recursive function
divide(d,range(d$x),range(d$y),0)
write_csv(results,'test.csv')
