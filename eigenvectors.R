library("EBImage")
library(png)
library(tiff)
library(abind)
library(raster)
filename = "v018-penn.9-1uB2D2-cropm"

sigma = 1

raw.img = readPNG(paste0("images/cropped pics/", filename, ".png"))

# Play with the gamma correction for the image by raising it to a power.
# Also apply Gaussian blur
img = gblur(raw.img^.01, sigma)

col.scale = gray.colors(100, start = 1, end = 0)

sigma = 5

# dx==TRUE: derivative in the x direction.  dx==FALSE: derivative in the y direction
findSlopes = function(x, dx){
  filter2(x, matrix(c(-.5 , 0, .5), ncol = ifelse(dx, 3, 1)))
}


dx = findSlopes(img, TRUE)
dy = findSlopes(img, FALSE)
dxx = findSlopes(dx, TRUE)
dyy = findSlopes(dy, FALSE)
dxy = findSlopes(dx, FALSE)

# Eigenvalues of a 2x2 matrix:
# 1/2[ (a11 + a22) +/- sqrt(4 * a12 * a21 + (a11 - a22)^2) ]
first.piece = dxx + dyy
second.piece = sqrt(4 * dxy^2 + (dxx - dyy)^2)

# Put the first and second eigenvalues into an NxNx2 array, where N is the
# number of rows/columns and 2 is the total number of eigenvalues we're using.
eigenvalues = abind(
  eigenvalues1 = 1/2 * (first.piece + second.piece),
  eigenvalues2 = 1/2 * (first.piece - second.piece),
  along = 3
)

eigenvalues[,,1]

# X * (eigenvalue - dxx) / dxy  = Y
# let X=1
theta = atan2(eigenvalues[,,1] - dxx, dxy)

color = matrix(
  hcl(
    h = theta/pi * 360, 
    c = pmax(eigenvalues[,,1], 0) / max(eigenvalues[,,1]) * 100,
    l = pmax(eigenvalues[,,1], 0) / max(eigenvalues[,,1]) * 100
  ),
  ncol = ncol(img)
)

zz = matrix(1:length(theta), ncol = ncol(theta))
png("a.png", width = 4000, height = 2000)
par(mfrow = c(1, 2))
plot(raster(raw.img), col = rev(col.scale))
plot(raster(zz), col = color)
dev.off()

