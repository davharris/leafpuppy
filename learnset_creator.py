#!/bin/python

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Button
import random


imgloc = '../images/v012-penn.10-1hA5D1-cropb.png'
currimg=plt.imread(imgloc)

square = 21

data=[]
resd={'dot':0,'noise':1,'vein':2}
currbox=0

def moveCurrBox(img, width):
    w=int(width/2)
    #i=random.randint(0,len(img)-1)
    ymax=len(img[0,:])
    xmax=len(img[:,0])
    xcenter=random.randint(w, xmax-w-1)
    ycenter=random.randint(w, ymax-w-1)
    global currBox
    currBox = img[xcenter-w:xcenter+w, ycenter-w:ycenter+w]

fig, ax = plt.subplots()
plt.subplots_adjust(bottom=0.2)
moveCurrBox(currimg,square)
drawing = plt.imshow(currBox, cmap=plt.cm.gray)

class DoAThing:
    data=[]
    def dot(self, event):
        data.append([currBox, resd['dot']])
        moveCurrBox(currimg, square)
        drawing.set_data(currBox)
        plt.draw()
    
    def noise(self, event):
        data.append([currBox, resd['noise']])
        moveCurrBox(currimg, square)
        drawing.set_data(currBox)
        plt.draw()
        
    def vein(self, event):
        data.append([currBox, resd['vein']])
        moveCurrBox(currimg, square)
        drawing.set_data(currBox)
        plt.draw()
    
    def ignore(self, event):
        moveCurrBox(currimg, square)
        drawing.set_data(currBox)
        plt.draw()
    
    def gtfo(self, event):
        plt.close()

callback = DoAThing()

axdot = plt.axes([0.05, 0.05, 0.1, 0.075])
axbg = plt.axes([0.25, 0.05, 0.1, 0.075])
axvein = plt.axes([0.45, 0.05, 0.1, 0.075])
axignore = plt.axes([0.65, 0.05, 0.1, 0.075])
axdone = plt.axes([0.85, 0.05, 0.1, 0.075])

bdot=Button(axdot, 'Dot')
bdot.on_clicked(callback.dot)

bbg=Button(axbg,'Noise')
bbg.on_clicked(callback.noise)
    
bvein=Button(axvein, 'Vein')
bvein.on_clicked(callback.vein)
    
bignore=Button(axignore, 'Ignore')
bignore.on_clicked(callback.ignore)
    
bdone=Button(axdone, 'Done')
bdone.on_clicked(callback.gtfo)

plt.show()
