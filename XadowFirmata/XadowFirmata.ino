#include "functions.h"
#include "HardwareSerial.h"
#include <Wire.h>
#include <SeeedOLED.h>
#include "FixedFirmata.h"

static byte TOGGLE_LED=0x01;
static byte QUERY_LED=0x02;
static byte CLEAR_DISPLAY=0x03;
static byte UPDATE_DISPLAY=0x04;
static byte QUERY_BATTERY=0x05;

int error=0;
int n=0;
int greenLed =0;

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


void initDisplay(){
   Wire.begin();	
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


void initIO(){
 
  // green led
 gLEDdir |= gLEDbit;
 gLEDport |= gLEDbit;
greenLed = 1;
}

unsigned char readCharge(void)
{
  unsigned char Temp = CHRGpin & CHRGbit;
  if(!Temp)
  {
    return CHARGE;
  }
  Temp = DONEpin & DONEbit;
  if(!Temp)
  {
    return DONE;
  }
  return NONE;
}

void sysexCallback(byte command, byte argc, byte *argv){
	
        if (command == QUERY_LED) {
            byte val[1];
            val[0] = greenLed ? HIGH : LOW ;
            Firmata.sendSysex(QUERY_LED, 0x01, val);
        } else if (command == TOGGLE_LED) {
            greenLed = argv[0];
            Serial.println("Led is " + greenLed);
          if (greenLed == 1){
               gLEDport &=~ gLEDbit; 
            } else {
               gLEDport |= gLEDbit; 
            }
        } else if (command == CLEAR_DISPLAY){
           resetDisplay(); 
          
        } else if (command == UPDATE_DISPLAY){
//          Serial.println("Update display");
          updateDisplay(argc,(char*)argv);
        } else if (command == QUERY_BATTERY) {
           int val[2];
           unsigned int rAD4 = analogRead(4);
           Serial.println("Battery " + rAD4);
           val[1]=rAD4;
           val[0]=readCharge();
           Firmata.sendSysex(QUERY_BATTERY, 0x02, (byte*) val);
        }


}


void setup(){
        Serial.begin(57600);
        delay(1000);
        Serial.println("Setup done");
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
}
