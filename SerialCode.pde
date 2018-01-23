//==========================================================================================================================
// CONTROLLER FOR SENDING OUT THE SERIAL CODES
//==========================================================================================================================
void sendSerialCode(int type) {

  switch (type) {

    case 1: // REQUEST DATA FROM THE ARDUINO
      port.write(87);
      break;

    case 2: // SEND STATE OF VIDEO MONITORING- send information to the arduino for rewarding animal
      port.write(90);
      port.write(int(trigState));    // whether the animal is in the trigger area or not
      port.write(int(collectState));    // whether the animal is in the trigger area or not
      port.write(int(trialState));    // whether the animal is in the trigger area or not
      port.write(mousePosX[49]);       // x position 
      port.write(mousePosY[49]);       // y position
      break;
      
//    case 3: // End of trial data from the arduino board
//    // data about reward delivery and solenoid
//      port.write(88); 
//      

  }
  
}



//==========================================================================================================================
// GATHER DATA FROM INCOMING SERIAL DATA
//==========================================================================================================================
void parseSerialData() {

    String input = port.readStringUntil('*');   
      
    if (input != null) {
      int[] serialVals = int(split(input, ","));
      String[] parameters = split(input, ',');
      
      switch (serialVals[0]) {
        
        case 1:        
          digIn1 = serialVals[1];
          digIn2 = serialVals[2];
          sendSerialCode(2);  
          break;
          
      }
            
    }
    
}