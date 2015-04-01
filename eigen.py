import numpy as np
from skimage import data
import matplotlib.pyplot as plt
from skimage import io
from skimage.feature import hessian_matrix, hessian_matrix_eigvals, hessian_matrix_det
from skimage.filters import gaussian_filter
from skimage.morphology import watershed, closing, opening
from scipy.stats import logistic


filename = "skeletons & matching cropped pics/cropped pics/v018-penn.9-1uB2D2-cropm.png"

coins = io.imread(filename)
coins = (np.mean(coins) - coins) / np.std(coins)


sigma = 1.

Hxx, Hxy, Hyy = hessian_matrix(coins, sigma=sigma, mode="wrap")


e1, e2 = hessian_matrix_eigvals(Hxx, Hxy, Hyy)

# How much bigger is the first eigenvalue's magnitude
# compared with the second?

condition = abs(e1/e2)

out = logistic.cdf(np.log(condition))

markers = np.zeros_like(out)
markers[out < 0] = 1
markers[out > np.percentile(out, 90)] = 2

plt.imshow(out)
plt.set_cmap('binary')
plt.colorbar()
plt.show()

