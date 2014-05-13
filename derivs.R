library("EBImage")
library(png)
library(tiff)
filename = "images/v020-m82.6-1hB1D2-cropt"

img = readPNG(paste0(filename, ".png"))

sigma = 3L

kern = makeBrush(
  sigma * 6 + 1, 
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



image(img, asp = 1, main = "intensity", col = heat.colors(100))
# image(dxx, asp = 1, main = "xx", col = heat.colors(100))
# image(dyy, asp = 1, main = "yy", col = heat.colors(100))
# image(dxy, asp = 1, main = "xy", col = heat.colors(100))


getEigenvalues = function(i, j){
  eigen(
    matrix(c(dxx[i+1, j], dxy[i, j], dxy[i, j], dyy[i, j+1]), ncol = 2), 
    only.values = TRUE
  )$values
}


eigenvalues = array(NA, c(nrow(dxy), ncol(dxy), 2))
for(i in 1:nrow(dxy)){
  for(j in 1:ncol(dxy)){
    eigenvalues[i, j, ] = getEigenvalues(i, j)
  }
  cat(".")
  if(i%%50 == 0){
    cat("\n")
  }
}

# skeleton = readTIFF(paste0(filename, ".tif"))
# truth = skeleton[c(-1, -500), c(-1, -500)]
#plot(c(eigenvalues[,,1]), c(eigenvalues[,,2]), pch = ".", col = truth + 1, cex = 2)

png("ridge.png", width = 1500, height = 1500, pointsize = 36)
par(mfrow = c(2, 2))
image(readPNG(paste0(filename, ".png")), asp = 1, main = "raw pixels", , col = gray.colors(100, start = 0, end = 1))
image(eigenvalues[,,1], asp = 1, main = "first eigenvalue", col = gray.colors(100, start = 1, end = 0))
image(eigenvalues[,,2], asp = 1, main = "second eigenvalue", col = gray.colors(100, start = 1, end = 0))
image(sqrt(pmax(eigenvalues[,,1], 0)^2 + pmax(eigenvalues[,,2], 0)^2), asp = 1, col = gray.colors(100, start = 1, end = 0), main = "ridge")
dev.off()


