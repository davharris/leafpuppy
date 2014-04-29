#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <opencv/cv.h>
#include <opencv/highgui.h>

#define BOXSIZE 10
#define BOXSIZEEQ 10
  
int *findCOM(IplImage*);
int *findDarkestRegion(IplImage*);
int *calcCDF(IplImage *);
IplImage* trueLocalEqImg(IplImage *);
IplImage* getSubimg(IplImage*, int, int, int);
IplImage* zoom(IplImage*, int);
IplImage* getEqImg(IplImage*);
IplImage* localEqImg(IplImage*);
IplImage** filterImg(IplImage*);
CvSeq* findCircles(IplImage *);

int main(int argc, char *argv[]){
	IplImage *img, *subimg, *currimg;
	IplImage **filtered;
	int *com;

	if(argc<2){
		printf("Usage: main <image-file-name>\n\7");
		exit(0);
	}

	img=cvLoadImage(argv[1], CV_LOAD_IMAGE_GRAYSCALE);
	
	if(!img){
		printf("Could not load image file: %s\n",argv[1]);
		exit(0);
	}

    subimg=getSubimg(img, 2,16, BOXSIZE);
	
	cvNamedWindow("mainImg", CV_WINDOW_AUTOSIZE); 
	cvMoveWindow("mainImg", 50, 50);
	cvShowImage("mainImg", img );

	/*cvNamedWindow("subImg", CV_WINDOW_AUTOSIZE);
	cvMoveWindow("subImg", 100,100);
	cvShowImage("subImg", zoom(subimg, 10));*/
	
	currimg = trueLocalEqImg(img);
	
	cvNamedWindow("localEqImg", CV_WINDOW_AUTOSIZE);
	cvMoveWindow("localEqImg", 100, 100);
	cvShowImage("localEqImg", currimg);
	
	/*filtered = filterImg(currimg);
	
	cvNamedWindow("Open", CV_WINDOW_AUTOSIZE);
	cvMoveWindow("Open", 150,150);
	cvShowImage("Open", filtered[0]);
	
	
	cvNamedWindow("Thresh", CV_WINDOW_AUTOSIZE);
	cvMoveWindow("Thresh", 200,200);
	cvShowImage("Thresh", filtered[1]);
	
	
	cvNamedWindow("Close", CV_WINDOW_AUTOSIZE);
	cvMoveWindow("Close", 250,250);
	cvShowImage("Close", filtered[2]);
	
	
	cvNamedWindow("Contour", CV_WINDOW_AUTOSIZE);
	cvMoveWindow("Contour", 300,300);
	cvShowImage("Contour", filtered[3]);*/
	
	cvWaitKey(0);

	/*com=findCOM(subimg);
	printf("The COM is %d, %d\n", com[0], com[1]);
	com=findDarkestRegion(subimg);
	printf("The darkest region is %d, %d\n", com[0], com[1]);*/

	//findCircles(subimg);
	cvReleaseImage(&img );
	cvReleaseImage(&subimg);
	return 0;
}

IplImage *localEqImg(IplImage *img){
	IplImage *newimg=cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	int i,j;
	cvCopy(img, newimg, NULL);
	//cvSmooth(newimg, newimg, CV_GAUSSIAN, 5, 5, 0,0);
	for (i=0; i<newimg->height; i+=BOXSIZEEQ){
		for (j=0; j<newimg->width; j+=BOXSIZEEQ){
			cvSetImageROI(newimg, cvRect(i,j,BOXSIZEEQ, BOXSIZEEQ));
			cvEqualizeHist(newimg, newimg);
			cvResetImageROI(newimg);
		}
	}
	cvSmooth(newimg, newimg, CV_GAUSSIAN, 3, 3, 0,0);
	return newimg;
}

IplImage *trueLocalEqImg(IplImage *img){
	IplImage *newimg=cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	IplImage *currimg;
	int *cdf;
	int i,j;
	uchar *currpix;
	cvCopy(img, newimg, NULL);
	for(i=0; i<img->height-BOXSIZEEQ; i++){
		for (j=0; j<img->width-BOXSIZEEQ; j++){
			currimg = getSubimg(img, i, j, BOXSIZEEQ);
			cdf=calcCDF(currimg);
			currpix=&((uchar*)newimg->imageData)[(i+BOXSIZEEQ/2)*newimg->widthStep+j+BOXSIZEEQ/2];
			*currpix=floor(255*(cdf[*currpix]-cdf[0])/(BOXSIZEEQ*BOXSIZEEQ-cdf[0]));
			//*currpix=cdf[*currpix];
		}
	}
	return newimg;
}

int *calcCDF(IplImage *img){
	int *hist = malloc(256*sizeof(int));
	int *cdf = malloc(256*sizeof(int));
	int i,j;
	for (i=0; i<256; i++) hist[i]=0;
	for(i=0; i<img->height; i++) for(j=0; j<img->width; j++) hist[ ((uchar*)img->imageData)[i*img->widthStep+j]]++;
	cdf[0]=hist[0];
	for(i=1; i<256; i++) cdf[i]=cdf[i-1]+hist[i];
	return cdf;
}

IplImage **filterImg(IplImage *img){
	IplImage *newimg = cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	IplImage *newimgcpy =cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	IplImage *contourimg=cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	IplImage **images=malloc(4*sizeof(IplImage*));
	IplConvKernel* structelem; 
	CvMemStorage *storage = cvCreateMemStorage(0);
	CvSeq* firstContour=NULL, *c;
	int i, nContours;
	
	for(i=0;i<4;i++) images[i]=cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	
	cvCopy(img, newimg, NULL);
	structelem = cvCreateStructuringElementEx(5, 5, 1, 1, CV_SHAPE_ELLIPSE, 0);
	cvMorphologyEx(newimg, newimg, NULL, structelem, CV_MOP_OPEN, 1 );
	cvCopy(newimg, images[0], NULL);
	//newimg=localEqImg(newimg);
	//cvEqualizeHist(newimg, newimg);
	cvAdaptiveThreshold(newimg, newimg, 255, CV_ADAPTIVE_THRESH_GAUSSIAN_C, CV_THRESH_BINARY, 7, 2 );
	cvCopy(newimg, images[1], NULL);
	structelem = cvCreateStructuringElementEx(2, 2, 1, 1, CV_SHAPE_ELLIPSE, NULL );
	cvMorphologyEx(newimg, newimg, NULL, structelem, CV_MOP_CLOSE, 1 );
	cvCopy(newimg, images[2], NULL);
	cvCopy(newimg, newimgcpy, NULL);
	nContours=cvFindContours(newimgcpy, storage, &firstContour, sizeof(CvContour), CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));
	
	for(c=firstContour; c!=NULL; c=c->h_next){
		if(cvContourArea(c, CV_WHOLE_SEQ, 0)>30.0){
			cvDrawContours(contourimg, c, cvScalarAll(255), cvScalarAll(255), -1, 1, 8, cvPoint(0,0));
		}
	}
	cvCopy(contourimg, images[3], NULL);
	/*for(i=0;i<nContours; i++){
		if(cvContourArea(contours, CV_WHOLE_SEQ, 0) > 30.0){
			cvDrawContours(contourimg, contours, cvScalarAll(255), cvScalarAll(255), -1, 1, 8, cvPoint(0,0));
		}
	}*/
	return images;
}

CvSeq* findCircles(IplImage* img){
	
    CvMemStorage* storage = cvCreateMemStorage(0);
    CvSeq *results;
    CvPoint pt;
    int i;
    float *p;
    
    //cvSmooth(img, img, CV_GAUSSIAN, 1,1,0,0);
    img = getEqImg(img);
    results = cvHoughCircles(img, storage, CV_HOUGH_GRADIENT, 1, 10, 1, 1, 2, 10);
    for (i=0; i>results->total; i++){
		p=(float *)cvGetSeqElem(results, i);
		printf("Circle: %f %f", p[0], p[1]);
		pt = cvPoint(cvRound(p[0]), cvRound(p[1]));
		cvCircle(img, pt, cvRound(p[2]), CV_RGB(0xff,0xff,0xff),1,8,0);
    }
    cvNamedWindow("Circle", CV_WINDOW_AUTOSIZE);
    cvShowImage("Circle", zoom(img, 10));
    cvWaitKey(0);
}

int *findCOM(IplImage* img){
/*Output: length-2 array, {i,j}-position of COM.
*/
	int i,j;
	int *com=malloc(2*sizeof(int));
	IplImage *eqImg = getEqImg(img);
	int currWeight, totWeight=0;
	com[0]=0;
	com[1]=0;
	for(i=0; i<eqImg->height; i++){
		for(j=0; j<eqImg->width; j++){
			currWeight=255-((uchar *)eqImg->imageData)[i*(eqImg->widthStep)+j];
			totWeight+=currWeight;
			com[0]+=(i*currWeight);
			com[1]+=(j*currWeight);
		}
	}
	//printf("%u\n",((uchar*)(eqImg->imageData))[1]);
	//((uchar *)eqImg->imageData)[0]=0;
	cvNamedWindow("eqHist", CV_WINDOW_AUTOSIZE); 
	cvMoveWindow("eqHist", 100, 100);
	cvShowImage("eqHist", zoom(eqImg,10) );
	cvWaitKey(0);
	//printf("totWeight, x, y, i, j: %d, %d, %d, %d, %d\n", totWeight, com[0], com[1], i, j);
	com[0]/=totWeight;
	com[1]/=totWeight;
	
	return com;
}

int *findDarkestRegion(IplImage* img){
    int i,j,k,m;
    int *xy=malloc(2*sizeof(int));
    IplImage *eqImg = getEqImg(img);
    int curr=0, temp;
    int box=3;
    for(i=0; i<eqImg->height - box; i++){
        for(j=0; j<eqImg->width - box; j++){
            temp=0;
            for(k=0; k<box; k++){
                for(m=0; m<box; m++){
                    temp+=255-((uchar *)eqImg->imageData)[(i+m)*eqImg->widthStep+j+k];
                }
            }
            if(temp>curr){
                xy[0]=i;
                xy[1]=j;
                curr=temp;
            }
        }
    }
    xy[0]+=box/2;
    xy[1]+=box/2;
    return xy;
}

IplImage *getEqImg(IplImage *img){
	IplImage *eqImg = cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	cvEqualizeHist(img, eqImg);
	return eqImg;
}

IplImage* getSubimg(IplImage* img, int x, int y, int boxsize){
    IplImage* subimg;
    cvSetImageROI(img, cvRect(x,y,boxsize,boxsize));
	subimg = cvCreateImage(cvGetSize(img), img->depth, img->nChannels);
	cvCopy(img, subimg, NULL);
	cvResetImageROI(img);
	return subimg;
}

IplImage* zoom(IplImage* img, int factor){
    IplImage* newImg=cvCreateImage(cvSize(img->width*factor, img->height*factor), img->depth, img->nChannels);
    cvResize(img, newImg, CV_INTER_AREA);
    return newImg;
}
