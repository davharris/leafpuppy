library("EBImage")
library(png)
library(tiff)
filename = "images/v018-penn.9-1uB2D2-cropb"

img = readPNG(paste0(filename, ".png"))

img = openingGreyScale(img, makeBrush(5, shape = "disc"))

sigma = 2

kern = makeBrush(
  201, 
  shape = "gaussian", 
  sigma = sigma
)


img = filter2(img, kern)



findSlopes = function(x){
  (x[-(1:2)] - x[-(length(x):(length(x) -1))]) / 2
}
findD2 = function(x, slopes){
  2 * (slopes + x[-(length(x):(length(x) - 1))] - x[-c(1, length(x))])
}


dx = dxx = img[ , -(1:2)] * NA
dy = dyy = t(dx)
dxy = dyx = matrix(NA, nrow = ncol(dx), ncol = nrow(dy))

for(i in 1:nrow(img)){
  dx[i, ]  = findSlopes(img[i, ])
  dxx[i, ] = findD2(x = img[i, ], slopes = dx[i, ])
}
for(i in 1:ncol(img)){
  dy[ , i]  = findSlopes(img[ , i])
  dyy[, i] = findD2(x = img[ , i], slopes = dy[ , i])
}
for(i in 1:ncol(dx)){
  dxy[ , i] = findSlopes(dx[ , i])
}
# Trim excess bits from dxx and dyy
dxx = dxx[-c(1, nrow(img)), ]
dyy = dyy[ , -c(1, nrow(img))]


# 1/2[ (a11 + a22) +/- sqrt(4 * a12 * a21 + (a11 - a22)^2) ]
first.piece = dxx + dyy
second.piece = sqrt(4 * dxy^2 + (dxx - dyy)^2)

eigenvalues1 = 1/2 * (first.piece + second.piece) # First eigenvalue
eigenvalues2 = 1/2 * (first.piece - second.piece) # Second eigenvalue

# image(img, asp = 1, main = "intensity", col = heat.colors(100))
# image(dxx, asp = 1, main = "xx", col = heat.colors(100))
# image(dyy, asp = 1, main = "yy", col = heat.colors(100))
# image(dxy, asp = 1, main = "xy", col = heat.colors(100))

png("ridge.png", width = 1500, height = 1500, pointsize = 36)
par(mfrow = c(2, 2))
image(readPNG(paste0(filename, ".png")), asp = 1, main = "raw pixels", , col = gray.colors(100, start = 0, end = 1))
image(eigenvalues1, asp = 1, main = "first eigenvalue", col = gray.colors(100, start = 1, end = 0))
image(eigenvalues2, asp = 1, main = "second eigenvalue", col = gray.colors(100, start = 1, end = 0))
image(sqrt(pmax(eigenvalues1, 0)^2 + pmax(eigenvalues2, 0)^2), asp = 1, col = gray.colors(100, start = 1, end = 0), main = "ridge")
dev.off()



# Dot removal
to.remove = eigenvalues2 > quantile(eigenvalues2, .97)
removed = readPNG(paste0(filename, ".png"))[-c(1, 500), -c(1, 500)]
removed[to.remove] = max(removed)
image(removed, asp = 1, main = "dot removal", , col = gray.colors(100, start = 0, end = 1))
