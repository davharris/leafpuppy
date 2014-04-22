#!/bin/python

import matplotlib.pyplot as plt
from matplotlib.widgets import Button
from matplotlib.patches import Rectangle
import matplotlib.gridspec as gridspec
import cPickle
#import random

imgloc = '../images/v012-penn.10-1hA5D1-cropb.png'
currimg=plt.imread(imgloc)

square = 13

data=[]
resd={'dot':0,'noise':1,'vein':2}
currbox=0

class clickBox(object):
    def __init__(self):
        
        #self.f, (self.ax1, self.ax2) = plt.subplots()
        self.f = plt.figure()
        self.gs=gridspec.GridSpec(5,4)
        self.ax1=plt.subplot(self.gs[:, 0:-1])
        self.ax2=plt.subplot(self.gs[2,-1])
        self.ax1.matshow(currimg, cmap=plt.cm.gray)
        self.rect = Rectangle((250-square/2,250-square/2), square, square, edgecolor='red', facecolor='none')
        self.subimg = currimg[self.rect.xy[1]:self.rect.xy[1]+square, self.rect.xy[0]:self.rect.xy[0]+square]
        self.ax2.matshow(self.subimg, cmap=plt.cm.gray)
        self.ax1.add_artist(self.rect)
        self.ax1.set_title('Click !')
        self.f.canvas.mpl_connect('button_press_event', self.on_click)
        
    def on_click(self, event):
        if event.inaxes is not self.ax1:
            #print 'd\'oh!'
            return
        self.ax1.add_artist(Rectangle(self.rect.xy, square, square, edgecolor='green', facecolor='none'))
        self.rect.xy = event.xdata-square/2, event.ydata-square/2
        self.subimg = currimg[self.rect.xy[1]:self.rect.xy[1]+square, self.rect.xy[0]:self.rect.xy[0]+square]
        data.append(self.subimg)
        self.ax2.matshow(self.subimg, cmap=plt.cm.gray)
        
        self.f.canvas.draw()

    def show(self):
        plt.show()


clickBox().show()

pkl_file = open('dots.pkl', 'a')
cPickle.dump(data, pkl_file)
pkl_file.close()
