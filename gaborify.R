# requires raw image (img) and Eigenvalue filters (d)

gaborify = function(img, 
                     n = 25, 
                     sigma = runif(1, 5, 20), 
                     gamma = rbeta(1, 3, 1), 
                     lambda = runif(1, 5, 20),
                     psi = runif(1, 0, 2 * pi)
){
  X = row(matrix(NA, n, n)) - ceiling(n/2)
  Y = col(matrix(NA, n, n)) - ceiling(n/2)
  thetas = seq(0, 345, 15) / 360 * 2 * pi
  
  maxed = -Inf
  avg = 0
  
  for(theta in thetas){
    theta = theta
    x_prime = X * cos(theta) + Y * sin(theta)
    y_prime = -X * sin(theta) + Y * cos(theta)
    
    k = exp(-(x_prime^2 + gamma^2 * y_prime^2) / 2 / sigma) * cos(2 * pi  * x_prime / lambda + psi)
    
    filtered = filter2(img, k)
    
    maxed = pmax(maxed, filtered)
    avg = avg + filtered / length(thetas)
  }
  cbind(c(maxed), c(avg))
}

dd = replicate(
  100,
  {
    cat(".")
    gaborify(img)
  }
)

ddd = cbind(dd, d)

train = sample.int(length(img), length(img) / 25)
library(gbm)
g = gbm(
  c(skeleton)[train] ~ ., 
  data = as.data.frame(ddd)[train, ], 
  distribution = "bernoulli",
  interaction.depth = 2,
  n.trees = 1000,
  shrinkage = .001,
  verbose = TRUE
)
pred = predict(g, as.data.frame(ddd), g$n.trees)
myplot(plogis(pred))
