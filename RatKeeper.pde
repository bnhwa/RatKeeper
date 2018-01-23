//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//online tracking of object position with event triggering and event reception for 2-target behavioral task
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


import processing.video.*;
import blobDetection.*;
import processing.net.*; 
import processing.serial.*;
import java.io.File;
Capture cam;
BlobDetection theBlobDetection;
Client myClient; 
String inStr; 
String fileName;
String mS = " ";
String dS = " ";
String dataPath;
String data = " ";
String paramData = " ";
String directoryName = "test";
PImage img;
PImage calc;
PImage bg;
boolean newFrame = false;
boolean bgSub = false;
boolean recording = false;
boolean persisting = false;
boolean communicating = false; // KM added 07.07
int numPixels;
int[] packetVals;
int zoom = 2;
float threshVal = 0.1;
int blurRadius = 3;

PrintWriter output;
PrintWriter parameters;

int[] mousePosX;
int[] mousePosY;

int eventControl = 1;

int digIn1 = 0;
int digIn2 = 0;
int digIn3 = 0;
int digIn4 = 0;

int digOut1 = 0;
int digOut2 = 0;
int digOut3 = 0;
int digOut4 = 0;

//->array of trigger reward probabilities
//->we can shuffle it at the beginning of every session
int nBoxes = 2;//number of target areas
boolean pos1; //->one arrangement of the boxes
int posListC[][] = {
{290,385,615,295}
};
int posList[][];
int[] rposList = {390,50,490,110};//corners of reward boxs
int pos; //->tells us which position arrangement of poslist

int trig_x_middle; //->denotes location of the actual trigger box
int trig_y_middle;

FloatList trig_prob;
int block = 0;
int blockSize = 50;
int whichTrig;

//->probability that one of the triggers will trigger reward
float p;
boolean beginState = false;
boolean drawState = false;
boolean endState = false;
boolean trigState = false;
boolean leftTrig = false;
boolean collectState = false;
boolean debug = false;
long time = 0;
long endTrial = 5000;//max number of trials
long iti = 2000;
long trigTime = 0;

int maxTrials = 50;
int trialState = 0;
int trialCnt = 1;
int hypShift = 0;
float[] trigProbs = {0.1,0.25,0.5,0.75,0.9};
float randAngle = 0;
float trigProb = 1;
int trigVariance = 0;
int trigMean = 0;

int xCenter = 436;
int yCenter = 81;
int boxWidth = 75;
int boxHeight = 75; 

//==========================================================================================================================
// PREPARE THE SERIAL PORT
//==========================================================================================================================
Serial port;
String portname;// = Serial.list()[5];
int baudrate = 115200;
boolean usePorts = false;
//==========================================================================================================================
// setup()
//==========================================================================================================================
String formatNumber(int n){
  return ((n<10) ? '0'+str(n) : str(n));
}
void setup() {
  size(960, 900);
  //->p(either positional arrangement of boxes) = 0.5
  //set it for entire session
  pos = int(random(posListC.length));
  initTriggerArea();
  //->probabilities array
  trig_prob = new FloatList();
  for (float e : trigProbs){
    trig_prob.append(e);
  }
  trig_prob.shuffle();
  // receive timestamps from a server controlling behavior
  //  myClient = new Client(this, "127.0.0.1", 5204); 
  String[] cameras = Capture.list();
  System.out.println(cameras);
    if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    } else {
      System.out.println("Available cameras:");
      for (String e : cameras){
        System.out.println(e);
      }
    }
    cam = new Capture(this, cameras[0]);
    println("Using " + cameras[0]);
    cam.start();     

  // Prepping background subtraction
  bg  = new PImage(960/zoom, 540/zoom);
  calc= new PImage(960/zoom, 540/zoom);
  numPixels = bg.width * bg.height;
  //===========================================
  // INITIALIZE SERIAL PORT
  //===========================================
  try {
     portname = Serial.list()[5];
     port = new Serial(this, portname, baudrate);
     println("Communicating over "+portname);
  } catch (Exception e) {
    if (usePorts == true){
      System.out.println(("no Serial Ports found"));
      exit();
    }
  }

  //===========================================        
  // BlobDetection
  //===========================================
  img = new PImage(bg.width, bg.height); 
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(false);
  theBlobDetection.setThreshold(0.10f); // will detect bright areas whose luminosity > 0.2f;
  //theBlobDetection.setConstants(int blobMaxNb, int blobLinesMaxNb, int blobTrianglesMaxNb)
  theBlobDetection.setConstants(1, 1000, 1000);

  mousePosX = new int[50];
  mousePosY = new int[50];
  
 //->can use this to change the conditions b/w blocks 
  hypShift = GenerateGaussianOffset(0, trigMean);
  String[] subdirs = {"VideoDataBuffer","DataBuffer"};
  dataPath = sketchPath()+"/data/";
  for (String s : subdirs){
    String path = dataPath + s + "/";
    File dataDir = new File(path);
    if (!dataDir.exists()){dataDir.mkdirs();}
  }
  dS = formatNumber(day());
  mS = formatNumber(month());
  // create a data file to keep track of data about behavioral performance (.csv)
  if (!debug){
    fileName = "v"+str(year())+"_"+mS+"_"+dS+"_"+str(hour())+"_"+str(minute());  
    output = createWriter(dataPath+"DataBuffer/"+fileName+".csv"); //added 07.07 KM "/../"
    // header information for the file- contains the file name
    String header = str(year())+","+str(month())+","+str(day())+","+str(hour())+","+str(minute());
    output.println(header);
    output.flush();
    // information about what is in each column
    String firstLine = "timestamp, trialNum, topXBox, topYBox, trigState, collectState, blobData(n,x,y,w,h)";
    output.println(firstLine);
    output.flush(); 
    // create a data file to keep track of trial parameter data (_p.csv)
    fileName = "v"+str(year())+"_"+mS+"_"+dS+"_"+str(hour())+"_"+str(minute());    
    parameters = createWriter(dataPath+"DataBuffer/"+fileName+"_p.csv");
  
  
    //information about what is in each column
      //->whichTrig = 0 for left and 1 for right
      //->leftProb = probability that trigger is at left box
    String firstLineParam = "trialNum, topXBox, topYBox, whichTrig, pos, leftProb, boxWidth, boxHeight, ITI, thresholdVal, time, Trig X, Trig Y";
    parameters.println(firstLineParam);
    parameters.flush();
  }
}

//==========================================================================================================================
// captureEvent()
//==========================================================================================================================
void captureEvent(Capture cam) {
  cam.read();
  calc.copy(cam, 0, 0, cam.width, cam.height, 0, 0, calc.width, calc.height);
  calc.filter(GRAY);
  if (!bgSub) {          
    bg.copy(calc, 0, 0, calc.width, calc.height, 0, 0, bg.width, bg.height);
  }
  newFrame = true;
  delay(8);
}

//==========================================================================================================================
// draw()
//==========================================================================================================================
void draw() {

  time = millis();
  theBlobDetection.setThreshold(threshVal); // will detect bright areas whose luminosity > threshVal;

  // ==================================================
  // retrieve new video data from cam
  // ==================================================
  if (newFrame) {
    newFrame=false;
    if (bgSub) {
      for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
        color currColor = calc.pixels[i];
        color bkgdColor = bg.pixels[i];
        int currR = (currColor >> 16) & 0xFF;
        int currG = (currColor >> 8) & 0xFF;
        int currB = currColor & 0xFF;
        // Extract the red, green, and blue components of the background pixel’s color
        int bkgdR = (bkgdColor >> 16) & 0xFF;
        int bkgdG = (bkgdColor >> 8) & 0xFF;
        int bkgdB = bkgdColor & 0xFF;
        // Compute the difference of the red, green, and blue values
        int diffR = abs(currR - bkgdR);
        int diffG = abs(currG - bkgdG);
        int diffB = abs(currB - bkgdB);
        calc.pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
      }
    }                

    //===========================================
    // PARSE INCOMING SERIAL DATA
    //=========================================== 
    if (usePorts && port.available() > 0) {
      println("Serial data coming back.");
      parseSerialData();
    }
    // ==================================================
    // calculate objects in the image
    // ==================================================
    img.copy(calc, 0, 0, calc.width, calc.height, 0, 0, img.width, img.height);
    fastblur(img, blurRadius);

    // ==================================================
    // display video
    // ==================================================
    image(cam, 0, 0, width, height);
    
    // ==================================================
    // detect objects
    // ==================================================
    theBlobDetection.computeBlobs(img.pixels);
    drawBlobsAndEdges(true, true);

    // ==================================================
    // record video (i.e. save each frame as an image - creates Massive buffers of images
    // ==================================================
    if (recording) saveFrame(dataPath+"VideoDataBuffer/screen-####.tga");

    // ==================================================
    // write blob info to file
    // ==================================================
    if (persisting) { 
      Blob b;
      String blobData = "";
      for (int j=0; j<1; j++) {
        b = theBlobDetection.getBlob(j);
        if (b!=null) {
          blobData += j+","+int(b.x*width)+","+int(b.y*height)+","+int(b.w*height)+","+int(b.h*height); // removed ","+ from the beginning
        }
      }

      // write behavior data
      data = str(time)+","+ int(trialCnt+1)+","+str(posList[whichTrig][0])+","+str(posList[whichTrig][1])+"," +int(trigState)+","+int(collectState)+","+blobData;
      output.println(data);
      output.flush();
    }

    //===========================================
    // ONLINE POSITION MONITOR
    //===========================================
    if (theBlobDetection.getBlobNb()>0) {
      Blob b2;
      b2 = theBlobDetection.getBlob(0);
      //if (!debug){
      mousePosX[49] = int(b2.x*width);
      mousePosY[49] = int(b2.y*height);
      //}else{
      //  mousePosX[49] = int(mouseX);
      //  mousePosY[49] = int(mouseY);
      //}
      strokeWeight(3);
      for (int i=1; i<50; i++) {//draw lines where mouse is
        stroke(0, 180, 240, i*2.5);
        line(mousePosX[i-1], mousePosY[i-1], mousePosX[i], mousePosY[i]);
        mousePosX[i-1] = mousePosX[i];
        mousePosY[i-1] = mousePosY[i];
      }
      strokeWeight(3);
    } 
    else {
      mousePosX[49] = -1;
      mousePosY[49] = -1;
    }

    // ==================================================
    // display some updates about the current video data
    // ==================================================
    fill(0);
    String stats = "Filename:"+fileName+"\nFrame rat->"+str(floor(frameRate))+
    "\nSubtract: "+bgSub+"\nTarget: "+str(xCenter)+","+str(yCenter)+"\nPersisting: "+persisting+"\nCommunicating: "
    +str(communicating)+"\nTrials: "+str(trialCnt)+"\nBlur Radius: "+str(blurRadius)+"\nBlob Thr: "+str(threshVal)
    +"\nStat->"+str(trialState)+"\nVarianc->"+str(trigVariance)+"\nTrialState->"+str(trialState)
    +"\nMousePos>"+str(mousePosX[49])+','+str(mousePosY[49])+"\ntriggerPos>"+str(trig_x_middle)+','+str(trig_y_middle);
    //+"\nbounds>"+str(posList[whichTrig][0])+","+str(posList[whichTrig][1])+","+str(posList[whichTrig][2])+","+str(posList[whichTrig][3]); // KM added +"\nCommunicating"+str(communicating); 07.07 
    text(stats, 5, 15);
    textSize(16);

    noStroke();
    fill(int(digIn1)*255, 0, 0);
    ellipse(100, 109, 15, 15); 

    //===========================================
    // TRIAL BASED TRIGGERING
    //=========================================== 

    switch(trialState) {

    case 0: // 'iti'

      // draw reward collection area
      stroke(240, 0, 180, 100);
      noFill();
      strokeWeight(10);
      rect(rposList[0], rposList[1], rposList[2]-rposList[0],rposList[3]-rposList[1]);

      collectState = false;   
      trigState = false;
      if (trialCnt > maxTrials) exit();
      if (time > endTrial+iti) {//trial initiates after entrial+iti milliseconds, allowing for mouse to receive reward via arduino port signal

        if (trialCnt > 40) {                    //->for us trigVariance should always be 0                                           
          hypShift = GenerateGaussianOffset(0, trigMean);
        } else {                                                                           // added 08.05 KM
          hypShift = GenerateGaussianOffset(0, trigMean);                                  // added 08.05 KM
        }                                                                                  // added 08.05 KM
        randAngle = random(0, 2*PI);
      //decides location of trigger depending on probabilities
        if ((trialCnt % blockSize) == 0 && trialCnt>0) { 
          block = block + 1; 
        }
        p = trig_prob.get(block); //changed this to after block change because probabilities
        if (random(1) <= p) {//for 2 target areas
          whichTrig=0;
        } else {
          whichTrig = 1;
        }
        trig_x_middle = posListC[pos][whichTrig*2];
        trig_y_middle = posListC[pos][whichTrig*2+1];
        trialState = 1;
      }

      break;

    case 1: // 'forage'
      // draw reward collection area
      stroke(240, 0, 180, 100);
      noFill();
      strokeWeight(10);
      rect(rposList[0], rposList[1], rposList[2]-rposList[0],rposList[3]-rposList[1]);
      trigState = false;
      for (int i=0; i<nBoxes; i++) {
        if (i==whichTrig){
          stroke(240, 180, 0, 100 + (100*int(i)));
        }else{
          stroke(0, 180, 240, 100 + (100*int(i)));
        }
        noFill();
        strokeWeight(10);
        rect(posList[i][0], posList[i][1], boxWidth, boxHeight);
      }
      if(onBox(mousePosX[49],mousePosY[49],mousePosX[48],posList[whichTrig][0],posList[whichTrig][1],
      posList[whichTrig][2], posList[whichTrig][3])) {
        trigState=true;
        trialState=2;
        trigTime = millis();
        }
    break;
    case 2: // 'collect'

      // draw reward collection area
      stroke(240, 0, 180, 100);
      noFill();
      strokeWeight(10);
      rect(rposList[0], rposList[1], rposList[2]-rposList[0],rposList[3]-rposList[1]);
      trigState = false;
      collectState = false;
      if(onBox(mousePosX[49],mousePosY[49],mousePosX[48],rposList[0],rposList[1],rposList[2], rposList[3])) {
      // output trial parameter data
        if (!debug) {
        paramData = int(trialCnt+1)+","+int(posList[whichTrig][0])+","+int(posList[whichTrig][1])+","+ int(whichTrig) + ","  + int(pos) + "," + p + "," + int(boxWidth)+","+int(boxHeight)+","+int(iti)+","+int(trigVariance)+","+str(time) + "," + trig_x_middle + "," + trig_y_middle; //+","+float(threshVal);
        parameters.println(paramData);
        parameters.flush();
        }
        collectState = true;
        trialCnt++;
        trialState = 0;
        endTrial = millis();
      }                 
      break;
    }
  }
}