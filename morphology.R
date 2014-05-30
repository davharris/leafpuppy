# Procedure based on code suggested by Stack Overflow user "dhanushka"
# http://stackoverflow.com/a/23177924/783153

library("EBImage")
library(png)
img = readPNG("images/v013-penn.2-1hA4C2-cropb.png")
kern = makeBrush(5, shape = "disc")

opened.image = openingGreyScale(
  img
)

# Based on procedure from ?EBImage::thresh
w=40
h=40
x = opened.image
f = makeBrush(size = w + 1, shape = "gaussian", sigma = 3)
blurred = filter2(x, f)
diff = (x-blurred)
diff = (diff - median(diff)) / sd(diff)
soft.thresh = plogis(2 * diff + 1.5)

processed.image = closing(
  soft.thresh,
  kern
)

imageplot = function(x, ...){
  image(x, ..., col = gray(seq(0, 1, length = 100)), asp = 1, axes = FALSE)
}



# 
# png("morphology.png", width = 2048, height = 2048)
# par(mfrow = c(2, 2))
# par(bty = "n")
# imageplot(img, main = "original")
# imageplot(processed.image, main = "processed")
# imageplot(soft.thresh, main = "soft threshold")
# imageplot(
#   thresh(
#     processed.image,
#     w = w,
#     h = h,
#     offset = -.02
#   ),
#   main = "hard threshold"
# )
# dev.off()

library(tiff)
skeleton = readTIFF("images/v020-m82.6-1hB1D2-cropt.tif")

image(skeleton, asp = 1)
imageplot(processed.image)


n.filters = 250
filters = array(NA, c(w + 1, w + 1, n.filters))

grating = matrix(NA, nrow = w + 1, ncol = w + 1)


filters[ , , n.filters] = filters[ , , n.filters] - mean(filters[ , , n.filters]) / 2
for(k in 1:n.filters){
  theta = runif(1, 0, 2 * pi)
  freq = runif(1, .01, .1)
  psi = runif(1, 0, 2 * pi)
  
  for(i in 1:nrow(grating)){
    for(j in 1:ncol(grating)){
      
      x_theta = i * cos(theta) + j * sin(theta)        
      grating[i, j] = sin(2 * pi * freq * x_theta + psi)
    }
  }
  filters[ , , k] = grating * makeBrush(
    w + 1, 
    shape = "gaussian", 
    sigma = runif(1, 2, 10)
  )
}


indices = sample.int(length(img), 5000)
x = sapply(
  1:n.filters, 
  function(i){
    z = if(i%%2){diff}else{img}
    filter2(diff, filters[ , , i])[indices]
  }
)
y = skeleton[indices]

library(gbm)
d = as.data.frame(
  cbind(
    x, 
    proc = processed.image[indices], 
    img = img[indices], 
    diff = diff[indices])
)

o = predict(glm(skeleton[indices] ~ d$diff, family = binomial))
g = gbm(
  y ~ . + offset(o), 
  data = d, 
  distribution = "bernoulli", 
  interaction.depth = 3,
  n.trees = 1E4
)


z = predict(g, n.trees = gbm.perf(g)) + o
glm(skeleton[indices] ~ z + 0, family = binomial)


# m = matrix(NA, nrow = 500, ncol = 500)
# m[indices] = z
# library(ggplot2)
# qplot(x= c(row(m)), y = c(col(m)), color = m) + scale_color_gradient2()
