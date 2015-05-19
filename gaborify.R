d = cbind(d, sapply(blurred, c))

# requires raw image (img) and Eigenvalue filters (d)
set.seed(1)

gaborify = function(img, 
                     sigma = exp(runif(1, 1, 3)), 
                     gamma = rbeta(1, 3, 1), 
                     lambda = runif(1, 2, 20),
                     psi = runif(1, 0, 2 * pi)
){
  n = ceiling(sigma + 1) * 3
  if(!n %% 2){n = n + 1}
  X = row(matrix(NA, n, n)) - ceiling(n/2)
  Y = col(matrix(NA, n, n)) - ceiling(n/2)
  thetas = seq(0, 345, 15) / 360 * 2 * pi
  
  print(c(sigma, gamma, lambda, n))
  
  
  maxed = -Inf
  avg = 0
  squared = 0
  
  for(theta in thetas){
    theta = theta
    x_prime = X * cos(theta) + Y * sin(theta)
    y_prime = -X * sin(theta) + Y * cos(theta)
    
    k = exp(-(x_prime^2 + gamma^2 * y_prime^2) / 2 / sigma) * cos(2 * pi  * x_prime / lambda + psi)
    
    filtered = filter2(img, k)
    
    maxed = pmax(maxed, filtered)
    avg = avg + filtered / length(thetas)
    squared = squared + filtered^2 / length(thetas)
  }
  var = c(squared - avg^2)
  plot(raster(k))
  cbind(max = c(maxed), mean = c(avg), cv = c(avg / sqrt(var)))
}

pcs = prcomp(d, scale. = TRUE)$x[,1:10]



dd = lapply(
  1:100,
  function(i){
    cat(".")
    gaborify(img)
  }
)
dds = do.call(cbind, dd)
colnames(dds) = paste0(rep(1:length(dd), each = 3), colnames(dds))

ddd = cbind(dds, pcs)

library(caret)
cols_to_remove = findCorrelation(cor(ddd))

ddd = ddd[, -cols_to_remove]

train = sample.int(length(img), length(img) / 25)
library(gbm)
g = gbm(
  c(skeleton)[train] ~ ., 
  data = as.data.frame(ddd)[train, ], 
  distribution = "bernoulli",
  interaction.depth = 3,
  n.trees = 100,
  weights = c(ifelse(skeleton == erode(skeleton), 2, 1))[train],
  shrinkage = .005,
  verbose = TRUE
)
g = gbm.more(g, 900)
pred = predict(g, as.data.frame(ddd), g$n.trees)
pred2 = predict(glm(c(skeleton) ~ pred, family = binomial), type = "response")

par(mfrow = c(1, 2))
myplot(pred2)
myplot(-raw.img)


srshrink.gbm(g, g$n.trees)