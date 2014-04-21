# Procedure based on code suggested by Stack Overflow user "dhanushka"
# http://stackoverflow.com/a/23177924/783153

library("EBImage")
library(png)
img = readPNG("images/wMTjH3L.png")
kern = makeBrush(5, shape = "disc")

processed.image = closing(
  openingGreyScale(gblur(img, radius = 3, sigma = 1.5), kern),
  kern
)

imageplot = function(x, ...){
  image(x, ..., col = gray(seq(0, 1, length = 12)), asp = 1, axes = FALSE)
}


# Based on procedure from ?EBImage::thresh
w=10;h=10;offset = -.01
x = processed.image
f = matrix(1, nc=2*w+1, nr=2*h+1) ; f=f/sum(f)
diff = (x-filter2(x, f))
diff = (diff - mean(diff)) / sd(diff)
soft.thresh = plogis(2 * diff + 1)

png("morphology.png", width = 2048, height = 2048)
par(mfrow = c(2, 2))
par(bty = "n")
imageplot(img, main = "original")
imageplot(processed.image, main = "processed")
imageplot(soft.thresh, main = "soft threshold")
imageplot(
  thresh(
    processed.image,
    w = w,
    h = h,
    offset = offset
  ),
  main = "hard threshold"
)
dev.off()