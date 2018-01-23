//==========================================================================================================================
// drawBlobsAndEdges()
//==========================================================================================================================
void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges){

	noFill();
	Blob b;
	EdgeVertex eA,eB;
	for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
	{
		b=theBlobDetection.getBlob(n);
		if (b!=null)
		{
			// Edges
			if (drawEdges)
			{
			     	strokeWeight(3);
				stroke(0,167,255,100);
				for (int m=0;m<b.getEdgeNb();m++)
				{
					eA = b.getEdgeVertexA(m);
					eB = b.getEdgeVertexB(m);
					if (eA !=null && eB !=null)
						line(
							eA.x*width, eA.y*height, 
							eB.x*width, eB.y*height
							);
				}
			}

			// Blobs
			if (drawBlobs){
				strokeWeight(3);
				stroke(255,0,0,100);
				rect(
					b.xMin*width,b.yMin*height,
					b.w*width,b.h*height
					);
			}

		}

      }
}

//==========================================================================================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
//==========================================================================================================================
void fastblur(PImage img,int radius)
{
 if (radius<1){
    return;
  }
  int w=img.width; //-20; // added -20 to make sure the trigger box is within the actual box that that animal can move in
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum,gsum,bsum,x,y,i,p,p1,p2,yp,yi,yw;
  int vmin[] = new int[max(w,h)];
  int vmax[] = new int[max(w,h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0;i<256*div;i++){
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0;y<h;y++){
    rsum=gsum=bsum=0;
    for(i=-radius;i<=radius;i++){
      p=pix[yi+min(wm,max(i,0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0;x<w;x++){

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if(y==0){
        vmin[x]=min(x+radius+1,wm);
        vmax[x]=max(x-radius,0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0;x<w;x++){
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for(i=-radius;i<=radius;i++){
      yi=max(0,yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0;y<h;y++){
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if(x==0){
        vmin[y]=min(y+radius+1,hm)*w;
        vmax[y]=max(y-radius,0)*w;

      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }

}

//==========================================================================================================================
// keyboard controls for execution
//==========================================================================================================================
void keyPressed() {
  
  
  // space key for subtraction- make sure animal isn't in cage at this point
  if (key == ' ') {
    if (bgSub) {
      bgSub = false;
    } else {
      bgSub = true;
    }
  }

  // r key for recording the image
  if (key == 'r' || key == 'R') {
    if (recording) {
      recording = false;
    } else 
      recording = true;
  }
 
  // p key for recording the x y coordinates
  if (key == 'p' || key == 'P') {
    if (persisting) {
      persisting = false;
    } else {
      persisting = true;
    }
  }

  if (key == '=') {
    blurRadius++;
  }

  if (key == '-') {
    blurRadius=blurRadius-1;
  }

  if (key == ']') {
    threshVal = threshVal + 0.02;
  }

  if (key == '[') {
    threshVal = threshVal - 0.02;
  }
  
  // s key to begin communication with the arduino board
  if (key == 's') {
    sendSerialCode(2);
    if (communicating) {         //KM added 07.07
      communicating = false; //KM added 07.07
    } else {                           //KM added 07.07
      communicating = true;  //KM added 07.07
    }                                   //KM added 07.07
  } 
  
  // j  key to shift the reward area to the left 
  if (key == 'j') {
    rposList[0]-=5;
    rposList[2] = rposList[0]+60;
  }
  
  //k key to shift the reward area to the right
  if (key == 'k') {
    rposList[0]+=5;
    rposList[2] = rposList[0]+60;
  }
  
  // i key to shift the reward area up
  if (key == 'i') {
    rposList[1]-=5;
    rposList[3] = rposList[1]+60;    
  }
  
  // m key to shift the reward area down
  if (key == 'm') {
    rposList[1]+=5;
    rposList[3] = rposList[1]+60;
  }  
  
  // changes the trigger box width and height 
  
  if (key == '1') {

    trigVariance = 0;
  }
  
  if (key == '2') {
    trigVariance = 0;
  }  
  
  if (key == '3') {
    trigVariance = 0;
  }  
  
  if (key == '4') {
    trigVariance = 0;
  }
  
  if (key == '5') {
    trigVariance = 0;
  }  
}