#include "functions.h"
#include <xadow.h>
#include "HardwareSerial.h"
#include <Wire.h>
#include <SeeedOLED.h>
#include "FixedFirmata.h"
#include "ADXL345.h"

static byte TOGGLE_LED=0x01;
static byte QUERY_LED=0x02;
static byte CLEAR_DISPLAY=0x03;
static byte UPDATE_DISPLAY=0x04;
static byte QUERY_BATTERY=0x05;
static byte TOGGLE_ACCEL=0x06;
static byte REPORT_ACCEL=0x07;
static byte REPORT_ACCEL_EVT=0x08;
static byte SET_TIME=0x09;
static byte DISPLAY_TIME=0x10;


int error=0;
int n=0;
int greenLed =0;
int enableAccelerometer=0;
ADXL345 adxl;


#define ADDRRTC         0x68

// day of week 
#define MON 1
#define TUE 2
#define WED 3
#define THU 4
#define FRI 5
#define SAT 6
#define SUN 7

unsigned char decToBcd(unsigned char val)
{
    return ( (val/10*16) + (val%10) );
}


unsigned char bcdToDec(unsigned char val)
{
    return ( (val/16*10) + (val%16) );
}


// time format is 
// year, month ,day, day_of_week, hour, minute, second
unsigned char setTime(unsigned char *dta)
{

    Wire.beginTransmission(ADDRRTC);
    Wire.write((unsigned char)0x00);
    Wire.write(decToBcd(dta[6]));           // 0 to bit 7 starts the clock
    Wire.write(decToBcd(dta[5]));
    Wire.write(decToBcd(dta[4]));           // If you want 12 hour am/pm you need to set bit 6
    Wire.write(decToBcd(dta[3]));
    Wire.write(decToBcd(dta[2]));
    Wire.write(decToBcd(dta[1]));
    Wire.write(decToBcd(dta[0]));
    Wire.endTransmission();

    return 1;
}

unsigned char getTime(unsigned char *dta)
{
    // Reset the register pointer
    Wire.beginTransmission(ADDRRTC);
    Wire.write((unsigned char)0x00);
    Wire.endTransmission();
    Wire.requestFrom(ADDRRTC, 7);
    // A few of these need masks because certain bits are control bits
    dta[6]  = bcdToDec(Wire.read());
    dta[5]  = bcdToDec(Wire.read());
    dta[4]  = bcdToDec(Wire.read());                // Need to change this if 12 hour am/pm
    dta[3]  = bcdToDec(Wire.read());
    dta[2]  = bcdToDec(Wire.read());
    dta[1]  = bcdToDec(Wire.read());
    dta[0]  = bcdToDec(Wire.read());

    return 1;
}

void TESTIO(void)
{
  DDRB|=0x0e;
  PORTB&=~0x0e;
  DDRF|=0x01;
  PORTF&=~0x01;
  DDRD&=~0x0f;

  PORTB|=0x04;
  PORTF|=0x01;
  delay(30);
  if(!(PIND&0x01))
  {
    error=1;
  }
  if(PIND&0x02)
  {
    error=1;
  }
  if(!(PIND&0x04))
  {
    error=1;
  }
  if(PIND&0x08)
  {
    error=1;
  }
  PORTB&=~0x04;
  PORTB|=0x0a;
  PORTF&=~0x01;
  delay(30);
  if(PIND&0x01)
  {
    error=1;
  }
  if(!(PIND&0x02))
  {
    error=1;
  }
  if(PIND&0x04)
  {
    error=1;
  }
  if(!(PIND&0x08))
  {
    error=1;
  }
  Serial.println(error);
}


void initBleSerial(){
  PORTB|=0x04;
  TESTIO();
  if(error==0)
  {
    DDRB|=0x81;
    for(n=0;n<40;n++)
    {
      PORTB&=~0x81;
      delay(50);
      PORTB|=0x81;
    }
  }
  
//  Serial1.begin(38400);
}

void initAccelerometer(){
    adxl.powerOn();

    //set activity/ inactivity thresholds (0-255)
    adxl.setActivityThreshold(75); //62.5mg per increment
    adxl.setInactivityThreshold(75); //62.5mg per increment
    adxl.setTimeInactivity(10); // how many seconds of no activity is inactive?

    //look of activity movement on this axes - 1 == on; 0 == off
    adxl.setActivityX(1);
    adxl.setActivityY(1);
    adxl.setActivityZ(1);

    //look of inactivity movement on this axes - 1 == on; 0 == off
    adxl.setInactivityX(1);
    adxl.setInactivityY(1);
    adxl.setInactivityZ(1);

    //look of tap movement on this axes - 1 == on; 0 == off
    adxl.setTapDetectionOnX(0);
    adxl.setTapDetectionOnY(0);
    adxl.setTapDetectionOnZ(1);

    //set values for what is a tap, and what is a double tap (0-255)
    adxl.setTapThreshold(50); //62.5mg per increment
    adxl.setTapDuration(15); //625us per increment
    adxl.setDoubleTapLatency(80); //1.25ms per increment
    adxl.setDoubleTapWindow(200); //1.25ms per increment

    //set values for what is considered freefall (0-255)
    adxl.setFreeFallThreshold(7); //(5 - 9) recommended - 62.5mg per increment
    adxl.setFreeFallDuration(45); //(20 - 70) recommended - 5ms per increment

    //setting all interrupts to take place on int pin 1
    //I had issues with int pin 2, was unable to reset it
    adxl.setInterruptMapping( ADXL345_INT_SINGLE_TAP_BIT,   ADXL345_INT1_PIN );
    adxl.setInterruptMapping( ADXL345_INT_DOUBLE_TAP_BIT,   ADXL345_INT1_PIN );
    adxl.setInterruptMapping( ADXL345_INT_FREE_FALL_BIT,    ADXL345_INT1_PIN );
    adxl.setInterruptMapping( ADXL345_INT_ACTIVITY_BIT,     ADXL345_INT1_PIN );
    adxl.setInterruptMapping( ADXL345_INT_INACTIVITY_BIT,   ADXL345_INT1_PIN );

    //register interrupt actions - 1 == on; 0 == off
    adxl.setInterrupt( ADXL345_INT_SINGLE_TAP_BIT, 1);
    adxl.setInterrupt( ADXL345_INT_DOUBLE_TAP_BIT, 1);
    adxl.setInterrupt( ADXL345_INT_FREE_FALL_BIT,  1);
    adxl.setInterrupt( ADXL345_INT_ACTIVITY_BIT,   1);
    adxl.setInterrupt( ADXL345_INT_INACTIVITY_BIT, 1);
}

void reportAccelerometer(int onOff){	
	enableAccelerometer = onOff;
}
void queryAccelerometer(){
	
    int x,y,z; 
    adxl.readAccel(&x, &y, &z); //read the accelerometer values and store them in variables x,y,z

    // Output x,y,z values - Commented out
    //Serial.print(x);
    //Serial.print(y);
    //Serial.println(z);


    //Fun Stuff!  
    //read interrupts source and look for triggerd actions
 
    //getInterruptSource clears all triggered actions after returning value
    //so do not call again until you need to recheck for triggered actions
    byte interrupts = adxl.getInterruptSource();
 
    // freefall
    if(adxl.triggered(interrupts, ADXL345_FREE_FALL)){
     Serial.println("freefall");
     //add code here to do when freefall is sensed
     sendAccelerometerEvent(ADXL345_FREE_FALL);
    } 
 
    //inactivity
    if(adxl.triggered(interrupts, ADXL345_INACTIVITY)){
     Serial.println("inactivity");
     //add code here to do when inactivity is sensed
     sendAccelerometerEvent(ADXL345_INACTIVITY);
    }
 
    //activity
    if(adxl.triggered(interrupts, ADXL345_ACTIVITY)){
     Serial.println("activity"); 
     //add code here to do when activity is sensed
     sendAccelerometerEvent(ADXL345_ACTIVITY);
    }
 
    //double tap
    if(adxl.triggered(interrupts, ADXL345_DOUBLE_TAP)){
     Serial.println("double tap");
     //add code here to do when a 2X tap is sensed
     sendAccelerometerEvent(ADXL345_ACTIVITY);
    }
 
    //tap
    if(adxl.triggered(interrupts, ADXL345_SINGLE_TAP)){
     Serial.println("tap");
     //add code here to do when a tap is sensed
     sendAccelerometerEvent(ADXL345_SINGLE_TAP);
    } 
	
}

void sendAccelerometerEvent(byte event){
  byte val[1];
  val[0] = event;
   Firmata.sendSysex(REPORT_ACCEL_EVT, 0x01, val);
}

void initDisplay(){
   SeeedOled.init();  //initialze SEEED OLED display
  DDRB|=0x21;        
  PORTB |= 0x21;

  resetDisplay();
}

void resetDisplay(){
  SeeedOled.clearDisplay();          //clear the screen and set start position to top left corner
  SeeedOled.setNormalDisplay();      //Set display to normal mode (i.e non-inverse mode)
  SeeedOled.setHorizontalMode();           //Set addressing mode to Page Mode
//  SeeedOled.setTextXY(0,0);          //Set the cursor to Xth Page, Yth Column 
  SeeedOled.putString("Xadow Firmata");
}

void updateDisplay(int argc, char* text){
    SeeedOled.clearDisplay();          //clear the screen and set start position to top left corner
    SeeedOled.setNormalDisplay();      //Set display to normal mode (i.e non-inverse mode)
    SeeedOled.setHorizontalMode();           //Set addressing mode to Page Mode
    for (int i=0;i<argc;i++)
    SeeedOled.putChar(text[i]);
      
}

void displayTime(){
    unsigned char* td = (unsigned char*) malloc(sizeof(unsigned char)*7);
    getTime(td);
    cout << "20" << td[0] << '/' << td[1] << '/' << td[2] << tabl;
    cout << td[4] << ":" << td[5] << ":" << td[6] << endl;

    String dateString;
    dateString += "20";
    dateString += td[0];
    dateString += "/";
    dateString += td[1];
    dateString += "/";
    dateString += td[2];
     
    String timeString;
    
    if (td[4] < 10) timeString +="0";
    timeString += td[4];
    timeString += ":";
    if (td[5] < 10) timeString +="0";
    timeString += td[5];
    timeString += ":";

    if (td[5] < 10) timeString +="0";
    timeString += td[5];

  
    SeeedOled.clearDisplay();          //clear the screen and set start position to top left corner
    SeeedOled.setNormalDisplay();      //Set display to normal mode (i.e non-inverse mode)
    SeeedOled.setPageMode();           //Set addressing mode to Page Mode
    SeeedOled.setTextXY(0,0);
    SeeedOled.putString(dateString.c_str());
    SeeedOled.setTextXY(2,0);
    SeeedOled.putString(timeString.c_str());
    
    free(td);
}


void initIO(){
 
	Xadow.greenLed(LEDON);
	greenLed = LEDON;
}



void sysexCallback(byte command, byte argc, byte *argv){
	
        if (command == QUERY_LED) {
            byte val[1];
            val[0] = (greenLed == LEDON) ? HIGH : LOW ;
            Firmata.sendSysex(QUERY_LED, 0x01, val);
        } else if (command == TOGGLE_LED) {
            greenLed = argv[0] == 1 ? LEDON : LEDOFF;
            Serial.println("Led is " + greenLed);
			Xadow.greenLed(greenLed);
        } else if (command == CLEAR_DISPLAY){
           resetDisplay(); 
          
        } else if (command == UPDATE_DISPLAY){
//          Serial.println("Update display");
          updateDisplay(argc,(char*)argv);
        } else if (command == QUERY_BATTERY) {
           byte val[2];
           val[1]=Xadow.getBatVol()*10;
           val[0]=Xadow.getChrgState();
           Serial.println(val[1]);
           Firmata.sendSysex(QUERY_BATTERY, 0x02, (byte*) val);
        } else if (command == SET_TIME) {
           unsigned char* time = (unsigned char*)argv;
           setTime(time);
        } else if (command == REPORT_ACCEL) {
           
          reportAccelerometer(argv[0]);
           
        } else if (command == DISPLAY_TIME) {
           displayTime(); 
        }


}


void setup(){
        Serial.begin(57600);
//        while(!Serial);
        Serial.println("Setup done");
	Xadow.init();
	Wire.begin();
	initAccelerometer();
        initDisplay();
        Stream& the_serial = Serial1;
	initBleSerial();
        initIO();
	Firmata.setFirmwareVersion(0,1);
	Firmata.attach(START_SYSEX, sysexCallback);
	Firmata.begin();
        //battery stuff
        analogReference(INTERNAL);
        analogRead(4);
        Serial.begin(57600);
}

void loop(){
	while(Firmata.available()){
		Firmata.processInput();
	}
	//delay(100);
	if (enableAccelerometer){
		queryAccelerometer();
		
	}
}
