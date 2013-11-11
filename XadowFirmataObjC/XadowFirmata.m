//
//  XadowFirmata.m
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "XadowFirmata.h"
#import "XadowUART.h"
#define START_SYSEX             0xF0 // start a MIDI SysEx message
#define END_SYSEX               0xF7 // end a MIDI SysEx message
#define REPORT_FIRMWARE         0x79 
#define PROTOCOL_VERSION        0xF9


#define TOGGLE_LED              0x01 // toggle led command
#define QUERY_LED               0x02
#define CLEAR_DISPLAY           0x03
#define UPDATE_DISPLAY          0x04
#define QUERY_BATTERY           0x05
#define TOGGLE_ACCEL            0x06
#define REPORT_ACCEL            0x07
#define REPORT_ACCEL_EVT        0x08
#define SET_TIME                0x09
#define DISPLAY_TIME            0x10




#define MON 1
#define TUE 2
#define WED 3
#define THU 4
#define FRI 5
#define SAT 6
#define SUN 7



@interface XadowFirmata ()

@property (nonatomic,assign)BOOL parsingSysEx;
@property (nonatomic,assign)int waitForData;
@property (nonatomic,strong)NSMutableData* receivedBuffer;
@property (nonatomic,assign)int executeMultiByteCommand;
@property (nonatomic,strong) void (^queryLedBlock)(BOOL enabled);
@property (nonatomic,strong) void (^chargeBlock)(uint8_t chargeStatus, float charge);
@property (nonatomic,strong) void (^accelBlock)(uint8_t accel_event);
@end

@implementation XadowFirmata

- (id)initWithUART:(XadowUART*)uart
{
    self = [super init];
    if (self) {
        self.uart = uart;
        self.waitForData=0;
        self.parsingSysEx=NO;
        self.executeMultiByteCommand = 0;
        self.receivedBuffer = [NSMutableData data];
    }
    return self;
}



- (void) startLoop {
    self.bgThread = [[NSThread alloc] initWithTarget:self selector:@selector(readLoop:) object:self];
    [self.bgThread start];
}


- (void)stopLoop {
    [self.bgThread cancel];
}



#pragma mark listening thread
- (void) readLoop:(id)sender {
    while (![[NSThread currentThread] isCancelled]) {
        if ([self.uart available]) {
            UInt8 byte = [self.uart read];
            //            NSLog(@"Received %02x", byte);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self parseResponse:byte];
            });
        } else {
            [NSThread sleepForTimeInterval:1/60];
        }
    }
}
#pragma mark message parsing

- (void) parseResponse:(UInt8)byte {
    UInt8 command;
    NSLog(@"%02x", byte);
    
    if (!self.parsingSysEx) {
        
        // waiting for data and byte is data
        if (self.waitForData && byte < 128){
            self.waitForData--;
            [self.receivedBuffer appendBytes:&byte length:1];
            
            if (self.executeMultiByteCommand != 0 && self.waitForData == 0) {
                uint8_t params[2];
                [self.receivedBuffer getBytes:&params length:2];
                switch(self.executeMultiByteCommand) {

                    case REPORT_FIRMWARE:
                        
                        NSLog(@"Firmware version %d.%d", params[0], params[1]);
                        break;
                    case PROTOCOL_VERSION:
                        NSLog(@"Protocol version %d.%d", params[0], params[1]);
                        break;
                        
                }
            }
        } else {
            // read the command + channel if any
            if(byte < 0xF0) {
                command = byte & 0xF0;
//                self.multiByteChannel = byte & 0x0F;
            } else {
                command = byte;
                // commands in the 0xF* range don't use channel data
            }
            switch (command) {
                case REPORT_FIRMWARE:
                case PROTOCOL_VERSION:
                    self.waitForData = 2;
                    self.executeMultiByteCommand = command;
                    self.receivedBuffer = [NSMutableData data];
                    break;
                case START_SYSEX:
                    self.parsingSysEx = YES;
                    self.receivedBuffer = [NSMutableData data];
                    break;
                default:
                    NSLog(@"Unkown command %02x", command);
                    break;
            }
        }
        
        
    } else {
        if (byte == END_SYSEX) {
            // end system message
            
            self.parsingSysEx = NO;
            [self parseSystemMessage];
        } else {
            // fill system message buffer
            
            [self.receivedBuffer appendBytes:&byte length:1];
      
        }
        
    }
    
    
}


- (void) parseSystemMessage {
    
    // do something with the message
    
    UInt8 firstByte;
    NSData* data = [NSData dataWithData:self.receivedBuffer];
    [data getBytes:&firstByte length:1];
    
    if (firstByte == REPORT_FIRMWARE) {
        
        [self parseSysexReportFirmware];
        
    } else if (firstByte == QUERY_LED) {
        
        
        UInt8 secondByte[2];
        [data getBytes:secondByte length:2];
        __block uint8_t byte = secondByte[1];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.queryLedBlock(byte);
        });
        
        
    } else if (firstByte == QUERY_BATTERY) {
        int count = self.receivedBuffer.length;
        UInt8 allBytes[5];
        [data getBytes:allBytes length:5];
        __block uint8_t chargeStatus = (allBytes[1] & 0x7F) | (allBytes[2]& 0x7F  << 7 );
        __block uint8_t charge = (allBytes[3] & 0x7F) | (allBytes[4]& 0x7F  << 7 ) ;
//
//        uint8_t chargeStatus = allBytes[1];
        float fcharge = charge/10.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.chargeBlock(chargeStatus,fcharge);
        });
        
    } else if (firstByte == REPORT_ACCEL_EVT) {
        UInt8 secondByte[2];
        [data getBytes:secondByte length:2];
        __block uint8_t byte = secondByte[1];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.accelBlock)
                self.accelBlock(byte);
        });
        
        
    }else {
        NSLog(@"Unknown Sysex message %@", self.receivedBuffer);
        
    }
    
    
    self.receivedBuffer = [NSMutableData data];

    
}
- (void) parseSysexReportFirmware {
    if (self.receivedBuffer.length >= 3){
        UInt8 params[3];
        [self.receivedBuffer getBytes:&params length:3];
        NSLog(@"Firmware version %c.%c", params[1] + '0', params[2] + '0');
    }
}


#pragma mark Firmata use case methods

-(void)queryFirmware {
    uint8_t buf[3] = { START_SYSEX, REPORT_FIRMWARE, END_SYSEX };
    [self.uart write:buf length:3];
    
}

-(void)queryLED:(void(^)(BOOL enabled))block{
    self.queryLedBlock = block;
    uint8_t buf[3] = { START_SYSEX, QUERY_LED, END_SYSEX };
    [self.uart write:buf length:3];
    
}


-(void) toggleLED:(BOOL)on {
    uint8_t buf[4] = { START_SYSEX, TOGGLE_LED, on, END_SYSEX };
    [self.uart write:buf length:4];
}

-(void)resetDisplay {
    uint8_t buf[3] = { START_SYSEX, CLEAR_DISPLAY, END_SYSEX };
    [self.uart write:buf length:3];
}

-(void)updateDisplay:(NSString *)text {
    
    uint8_t* buf = malloc(sizeof(uint8_t) * (2+MAX(text.length,18)));
    const char* textBuf = [text cStringUsingEncoding:NSASCIIStringEncoding];
    int count = 0;
    buf[count++]=START_SYSEX;
    buf[count++]=UPDATE_DISPLAY;
    for (int idx=0;idx<text.length;idx++){
        buf[count++]=textBuf[idx] & 0x7F;
//        buf[count++]=textBuf[idx] >> 7 & 0x7F;
    }
    while(count<16){
        buf[count++]=' ' & 0x7f;
    }
    buf[count++]=END_SYSEX;
    [self.uart write:buf length:count];
//    free(buf);
}

- (void) queryBattery:(void(^)(uint8_t chargeStatus, float charge))chargeVlock{
    self.chargeBlock = chargeVlock;
    uint8_t buf[3] = { START_SYSEX, QUERY_BATTERY, END_SYSEX };
    [self.uart write:buf length:3];

}
- (void)queryAccelerometer:(void(^)(uint8_t accel_event))accelBlock {
    self.accelBlock = accelBlock;
}
- (void)toggleAccelerometer:(BOOL)onOff {
    uint8_t buf[4] = { START_SYSEX, REPORT_ACCEL, onOff, END_SYSEX };
    [self.uart write:buf length:4];
    if (!onOff){
        self.accelBlock = nil;
    }
    
}
- (void)setTimeWithYear:(int)year month:(int)month day:(int)day weekDay:(int)weekDay hour:(int)hour minutes:(int)minutes seconds:(int)seconds {
    uint8_t buf[10] = { START_SYSEX, SET_TIME, year, month, day, weekDay, hour, minutes, seconds, END_SYSEX };
    [self.uart write:buf length:10];
    
}
- (void)displayTime {
    uint8_t buf[3] = { START_SYSEX, DISPLAY_TIME, END_SYSEX };
    [self.uart write:buf length:3];
    
}


@end
