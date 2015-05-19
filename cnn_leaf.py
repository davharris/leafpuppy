from keras.preprocessing.image import ImageDataGenerator
from keras.models import Sequential
from keras.layers.core import Dense, Dropout, Activation, Flatten
from keras.layers.convolutional import Convolution2D, MaxPooling2D
from keras.optimizers import SGD, Adadelta, Adagrad
from keras.utils import np_utils, generic_utils
from six.moves import range

batch_size = 32

nb_epoch = 1

# the data, shuffled and split between tran and test sets

# (X_train, y_train), (X_test, y_test) = IMPORT DATA HERE
# print(X_train.shape[0], 'train samples')
# print(X_test.shape[0], 'test samples')

model = Sequential()

# In convolutional layers, arguments are n_outgoing, n_incoming, size, size
model.add(Convolution2D(32, 1, 5, 5, border_mode='valid'))  # output 496x496
model.add(Activation('relu'))

model.add(MaxPooling2D(poolsize=(2, 2)))                    # output 248x248
model.add(Dropout(0.5))

model.add(Convolution2D(32, 32, 3, 3, border_mode='valid')) # output 246x246
model.add(Activation('relu'))

model.add(MaxPooling2D(poolsize=(2, 2)))                    # output 123x123
model.add(Dropout(0.5))

model.add(Convolution2D(1, 32, 3, 3, border_mode='valid'))  # output 121x121
model.add(Activation('sigmoid'))

# let's train the model using SGD + momentum (how original).
sgd = SGD(lr=0.01, decay=1e-4, momentum=0.9, nesterov=True)
model.compile(loss='mse', optimizer=sgd)  # MSE *might* make sense.
                                          # See if I can use log loss with non-binary data


# X_train = X_train.astype("float32")
# X_test = X_test.astype("float32")
# X_train /= 255
# X_test /= 255
model.fit(X_train, Y_train, batch_size=batch_size, nb_epoch=nb_epoch)

score = model.evaluate(X_test, Y_test, batch_size=batch_size)
print('Test score:', score)