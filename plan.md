# The plan

Pipeline:
* For each pixel, find its two eigenvalues and the direction of its eigenvector
  * **Status:** already implemented in eigenvectors.R
* Rotate image patches to theta==0 as a preprocessing step?
* Unsupervised feature extraction using RICA on image patches
  * Original paper: http://ai.stanford.edu/~ang/papers/nips11-ICAReconstructionCost.pdf
  * Google cat detector paper: https://static.googleusercontent.com/media/research.google.com/en/us/archive/unsupervised_icml2012.pdf
  * Student paper: http://cs229.stanford.edu/proj2011/GuptaSadhwani-NonlinearExtensionsOfReconstructionICA.pdf
  * Tutorial (see also the "Exercise: RICA" page) http://ufldl.stanford.edu/tutorial/unsupervised/RICA/
  * (Alternatively, use an existing autoencoder implementation)
* Convolve the images with the extracted weight matrices, returning the degree to which each pixel's surrounding patch activates each hidden unit.
* Run a standard black-box supervised classifier on the results
  * Auxiliary features?
    * Histogram of image intensities to help deal with intensity/contrast
  * SVM classifier? RBF kernel?
  * Something that can run online/in minibatches, in case memory constraints are a problem?
