from __future__ import print_function
import matplotlib.pyplot as plt

import matplotlib
import numpy as np
from scipy import ndimage as nd

from skimage import data
from skimage.util import img_as_float
from skimage.filter import gabor_kernel


from skimage.feature import hog
from skimage import data, color, exposure

# Includes code modified from http://scikit-image.org/docs/dev/auto_examples/plot_gabor.html#example-plot-gabor-py

image = img_as_float(data.load('/Users/davidharris/Downloads/untitled.png'))

# prepare filter bank kernels
kernels = []
for theta in (4, 3, 2, 1):
    theta = theta / 4. * np.pi
    for sigma in (1, 3):
        for frequency in (0.05, 0.25):
            kernel = np.real(gabor_kernel(frequency, theta=theta,
                                          sigma_x=sigma, sigma_y=sigma))
            kernels.append(kernel)



brick = img_as_float(data.load('/Users/davidharris/Downloads/untitled.png'))

outputs = [nd.convolve(brick, kernel, mode='nearest') for kernel in kernels]

print(outputs)
