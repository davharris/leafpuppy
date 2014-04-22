#!/bin/python

import pylab as pl
import cPickle
import matplotlib.pyplot as plt
from sklearn import svm, metrics
import numpy as np
import sys

square = 13
imgloc = '../images/v012-penn.10-1hA5D1-cropb.png'
resd={'dot':0,'noise':1,'vein':2}
currimg=plt.imread(imgloc)

pkl_file=open('dots.pkl', 'r')
dots = cPickle.load(pkl_file)
pkl_file.close()
pkl_file=open('noise.pkl', 'r')
noise = cPickle.load(pkl_file)
pkl_file.close()
pkl_file=open('veins.pkl','r')
veins = cPickle.load(pkl_file)
pkl_file.close()

#dots = zip(dots, [0 for i in range(len(dots))])
#noise = zip(noise, [1 for i in range(len(noise))])
#veins = zip(veins, [2 for i in range(len(veins))])

print np.shape(np.asarray(dots))
print np.shape(np.asarray(noise))
print np.shape(np.asarray(veins))

dots_data = np.asarray(dots).reshape((len(dots),-1))
noise_data= np.asarray(noise).reshape((len(noise),-1))
veins_data= np.asarray(veins).reshape((len(veins),-1))

data = np.concatenate((np.concatenate((dots_data,noise_data)),veins_data))

print len(data)

target = [resd['dot'] for i in range(len(dots_data))] + [resd['noise'] for i in range(len(noise_data))] + [resd['vein'] for i in range(len(veins_data))]

print len(target)


classifier = svm.SVC(gamma=0.001)

classifier.fit(data, target)

tmpx, tmpy = len(currimg[0][:]), len(currimg[:][0])

final_image=np.ones((tmpy,tmpx))

blocks=[]
print 'Going through the blocks...'
sys.stdout.flush()

for i in [i+square/2 for i in xrange(tmpy-square)]:
    for j in [j+square/2 for j in xrange(tmpx-square)]:
        currblock=currimg[i-square/2:i+square/2+1,j-square/2:j+square/2+1]
        blocks.append(currblock)

blocks=np.asarray(blocks)
print np.shape(blocks)
blocks = np.asarray(blocks).reshape(len(blocks),-1)
print np.shape(blocks)

print 'About to make predictions...'
sys.stdout.flush()

predicted = classifier.predict(blocks)

voting = np.zeros((tmpy, tmpx, 3))
print 'About to count votes...'
sys.stdout.flush()

for p in xrange(len(predicted)):
    j=p%(tmpx-square)+square/2 
    i=(p-j+square/2)/(tmpx-square)+square/2
    #[i,j] are the coordinates of the center of that box
    #since p=(i-s/2)(X-s)+j-s/2
    for y in range(i-square/2,i+square/2):
        for x in range(j-square/2,j+square/2):
            voting[y,x][predicted[p]]+=1

for i in xrange(tmpy):
    for j in xrange(tmpx):
        if voting[i,j].argmax()==resd['vein']:
            final_image[i,j]=0
            
plt.imshow(final_image, cmap=plt.cm.gray)
plt.show()
#for i in [i+square/2 for i in xrange(tmpx-square)]:
#    for j in [j+square/2 for j in xrange(tmpy-square)]:
#        for k in range(i-square/2,i+square/2+1):
#            for 
