library("EBImage")
library(png)
library(tiff)
library(abind)
library(raster)
filename = "v018-penn.9-1uB2D2-cropt"

raw.img = readPNG(paste0("skeletons & matching cropped pics/cropped pics/", filename, ".png"))

breaks = seq(0, 1, .05)
col.scale = gray.colors(length(breaks), start = 1, end = 0)

myplot = function(x){
  image(raster(matrix(x, ncol = 500)), col = col.scale, maxpixels = 500^2, asp = 1)
}

# dx==TRUE: derivative in the x direction.  dx==FALSE: derivative in the y direction
findSlopes = function(x, dx){
  filter2(x, matrix(c(-.5 , 0, .5), ncol = ifelse(dx, 3, 1)))
}


eig = function(img, sigma){
  
  img = gblur(img, sigma)
  
  dx = findSlopes(img, TRUE)
  dy = findSlopes(img, FALSE)
  dxx = findSlopes(dx, TRUE)
  dyy = findSlopes(dy, FALSE)
  dxy = findSlopes(dx, FALSE)
  
  # Eigenvalues of a 2x2 matrix:
  # 1/2[ (a11 + a22) +/- sqrt(4 * a12 * a21 + (a11 - a22)^2) ]
  first.piece = dxx + dyy
  second.piece = sqrt(4 * dxy^2 + (dxx - dyy)^2)
  
  r = sqrt(dx^2 + dy^2)
  theta = pi + atan2(dx, dy)
  
  theta_bins = sapply(
    0:7,
    function(i){
      c(gblur((theta > pi/4 * i & theta < pi / 4 * (i + 1)) * r, sigma))
    }
  )
  H = -rowSums(ifelse(theta_bins > 1E-8, theta_bins * log(theta_bins), 0))
  
  
  list(
    e1 = 1/2 * (first.piece + second.piece),
    e2 = 1/2 * (first.piece - second.piece),
    det = dxx * dyy - dxy^2,
    r = r,
    H = H
  )
}

f = function(img, sigma){
  eigs = eig(img, sigma)
  curviness = sqrt(eigs[[1]]^2 + eigs[[2]]^2)
  
  out = data.frame(
    e1 = c(eigs$e1), 
    e2 = c(eigs$e2), 
    r = c(eigs$r),
    H = eigs$H,
    det = c(eigs$det),
    log_condition = log(c(abs(eigs[[1]]/eigs[[2]])))
  )
  colnames(out) = paste0(colnames(out), "_", sigma)
  
  out
}


# Modeling ----------------------------------------------------------------

gamma = .01

img = medianFilter(raw.img, 2)@.Data[,,1]
img = 1 - img^gamma
img = (img - gblur(img, 20))
img = img - min(img)
img = img / max(img)
img = 1 - img

myplot(img)

skeleton = readTIFF(paste0("skeletons & matching cropped pics/traced skeletons/", filename, ".tif"))

sigmas = 1.6^(seq(-1, 5))

blurred = lapply(
  sigmas,
  function(x){gblur(img, x)}
)

d = do.call(
  cbind,
  lapply(
    sigmas,
    function(sigma){
      f(img, sigma)
    }
  )
)

d = cbind(
  d, 
  sapply(
    1:length(sigmas[-1]),
    function(i){
      blurred[[i+1]] - blurred[[i]]
    }
  )
)

train = sample.int(nrow(d), nrow(d) / 5)

library(gbm)
g = gbm(
  c(erode(skeleton))[train] ~ ., 
  data = d[train, ], 
  distribution = "bernoulli",
  interaction.depth = 2,
  n.trees = 100,
  shrinkage = .1,
  verbose = TRUE
)


p = predict(g, newdata = d, n.trees = g$n.trees, type = "response")
pp = predict(glm(c(skeleton) ~ c(qlogis(p)), family = binomial), type = "response")

par(mfrow = c(1, 2))
myplot(1-raw.img)
myplot(pp)



stop()

# Find the angle of the dominant eigenvector
# Algebra says eigenvector falls along this line: Y=X * (eigenvalue - dxx) / dxy
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
