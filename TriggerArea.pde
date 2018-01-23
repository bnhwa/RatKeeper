//==========================================================================================================================
// Helper code for generating the trigger boxes and checking if objects are in them
//==========================================================================================================================
boolean onBox(int mpx1, int mpy1, int mpx2, int tLeftX, int tLeftY, int bRightX, int bRightY) {
  return (mpx1 > tLeftX && mpx1 < (bRightX)  && mpx2 > tLeftX && mpx2 < (bRightX) && mpy1 > (tLeftY) && mpy1 < (bRightY));// && mpx2 > tLeftX && mpx2 < (bRightX) 
}

void initTriggerArea() {
  
  int wAdjust = boxWidth/2;
  int hAdjust = boxHeight/2;
  posList = new int[posListC[pos].length/2][4];//l,r
  for (byte i=0; i< nBoxes; i++){
    int[] temp  = {posListC[pos][i*2]-wAdjust,posListC[pos][1+i*2]-hAdjust,
    posListC[pos][i*2]+wAdjust,posListC[pos][1+i*2]+hAdjust};
    posList[i] = temp;
  }
}
int GenerateGaussianOffset(float variance, float mean) {

  float x = 0;
  float y = 0;
  float s = 2;

  while (s>1) {
    x=random(-1,1);
    y=random(-1,1);
    s = (x*x) + (y*y);
  }	
  float unscaledRandNum = x*( sqrt(-2*log(s) / s) );
  return int( (unscaledRandNum*variance) + mean );
}