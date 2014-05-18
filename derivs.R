library("EBImage")
library(png)
library(tiff)
library(abind)
library(raster)
filename = "v018-penn.9-1uB2D2-cropm"

raw.img = readPNG(paste0("images/cropped pics/", filename, ".png"))

# Play with the gamma correction for the image by raising it to a power
img = raw.img^.01


sigma = 16

# This is uglier than I'd like and might be worth rewriting.  The slope is the
# half the difference between pixel 3 and pixel 1 in a sliding window.
findSlopes = function(x){
  (x[-(1:2)] - x[-(length(x):(length(x) -1))]) / 2
}

# Also ugly and worth rewriting.  Second derivative (d/dxx or d/dyy) is the 
# deviation from linearity.
findD2 = function(x, slopes){
  2 * (slopes + x[-(length(x):(length(x) - 1))] - x[-c(1, length(x))])
}

findHessianEigenvalues = function(img, sigma){  
  
  # Gaussian blur
  img = filter2(
    img, 
    makeBrush(
      201, 
      shape = "gaussian", 
      sigma = sigma
    )
  )
  
  # Allocate memory for derivatives
  dx = dxx = img[ , -(1:2)] * NA  # Two pixels narrower than the original image
  dy = dyy = t(dx)                # Two pixels shorter than the original image
  dxy = dyx = matrix(NA, nrow = ncol(dx), ncol = nrow(dy)) # both
  
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
  
  # Eigenvalues of a 2x2 matrix:
  # 1/2[ (a11 + a22) +/- sqrt(4 * a12 * a21 + (a11 - a22)^2) ]
  first.piece = dxx + dyy
  second.piece = sqrt(4 * dxy^2 + (dxx - dyy)^2)
  
  # Put the first and second eigenvalues into an NxNx2 array, where N is the
  # number of rows/columns and 2 is the total number of eigenvalues we're using.
  abind(
    eigenvalues1 = 1/2 * (first.piece + second.piece),
    eigenvalues2 = 1/2 * (first.piece - second.piece),
    along = 3
  )
}

eigenvalues = findHessianEigenvalues(img, sigma)

# Set up plotting canvas for ridge.png
png("ridge.png", width = 2000, height = 2000, pointsize = 36)
par(mfrow = c(2, 2))

# plot(raster(x)) is much faster than image(x)
plot(raster(readPNG(paste0("images/cropped pics/", filename, ".png"))), asp = 1, main = "raw pixels", , col = gray.colors(100, start = 0, end = 1))
plot(raster(pmax(eigenvalues[,,1], 0)), main = "first eigenvalue", col = gray.colors(100, start = 0, end = 1))
plot(raster(eigenvalues[,,2], 0), main = "second eigenvalue", col = gray.colors(100, start = 1, end = 0))
plot(raster(sqrt(pmax(eigenvalues[,,1], 0)^2 + pmax(eigenvalues[,,2], 0)^2)), col = gray.colors(100, start = 0, end = 1), main = "ridge")

# Close up the plot
dev.off()



# Dot removal -------------------------------------------------------------
# Identify the top few percent of the second eigenvalues, and 
# make the corresponding pixels white
to.remove = eigenvalues[,,2] > quantile(eigenvalues[,,2], .96)
removed = readPNG(paste0("images/cropped pics/", filename, ".png"))[-c(1, 500), -c(1, 500)]
removed[to.remove] = max(removed)
plot(raster(removed), main = "dot removal", col = gray.colors(100, start = 0, end = 1))



# Cheating classifier -----------------------------------------------------
# Simple "cheating" classifier based on a few % of the pixels in one image

# Ground truth from undergrads
y = readTIFF(paste0("images/traced skeletons/", filename, ".tif"))[-c(1, 500), -c(1, 500)]

makeFeatures = function(img, raw.img){
  data.frame(
    apply(findHessianEigenvalues(img, 1), 3, c),
    apply(findHessianEigenvalues(img, 2), 3, c),
    apply(findHessianEigenvalues(img, 4), 3, c),
    apply(findHessianEigenvalues(img, 8), 3, c),
    apply(findHessianEigenvalues(img, 16), 3, c),
    c(img[-c(1, 500), -c(1, 500)]), 
    c(raw.img[-c(1, 500), -c(1, 500)]), 
    c(
      filter2(
        img[-c(1, 500), -c(1, 500)], 
        makeBrush(
          201, 
          shape = "gaussian", 
          sigma = 5
        )
      )
    )
  )
}

data = scale(makeFeatures(img = img, raw.img = raw.img))
data = cbind(data, y = c(y))


library(nnet)
subsample = sample.int(nrow(data), 5E4)
g = nnet(
  y ~ ., 
  data = data[subsample, ],
  entropy = TRUE,
  size = 20,
  decay = .5,
  maxit = 1E3
)

png("classifier.png", height = 1000, width = 3000, pointsize = 36)
par(mfrow = c(1, 3))
image(
  raw.img,
  asp = 1, 
  main = "raw", 
  col = gray.colors(100, start = 0, end = 1)
)
image(
  matrix(predict(g, data), ncol = 498), 
  asp = 1, 
  main = "predictions", 
  col = gray.colors(100, start = 1, end = 0)
)
image(
  y, 
  asp = 1, 
  main = "ground truth", 
  col = gray.colors(100, start = 1, end = 0)
)
par(mfrow = c(1, 1))
dev.off()

img[!(1:length(img) %in% subsample)] = min(img, na.rm = TRUE)
