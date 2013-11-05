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

@interface XadowFirmata ()

@property (nonatomic,assign)BOOL parsingSysEx;
@property (nonatomic,assign)int waitForData;
@property (nonatomic,strong)NSMutableData* receivedBuffer;
@property (nonatomic,assign)int executeMultiByteCommand;
@property (nonatomic,strong) void (^queryLedBlock)(BOOL enabled);
@property (nonatomic,strong) void (^chargeBlock)(uint8_t chargeStatus, uint8_t charge);

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
        UInt8 allBytes[5];
        [data getBytes:allBytes length:5];
        __block uint8_t chargeStatus = (allBytes[1] & 0x7F) | (allBytes[2]& 0x7F  << 7 );
        __block uint8_t charge = (allBytes[3] & 0x7F) | (allBytes[4]& 0x7F  << 7 ) ;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.chargeBlock(chargeStatus,charge);
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

- (void) queryBattery:(void(^)(uint8_t chargeStatus, uint8_t charge))chargeVlock{
    self.chargeBlock = chargeVlock;
    uint8_t buf[3] = { START_SYSEX, QUERY_BATTERY, END_SYSEX };
    [self.uart write:buf length:3];

}


@end
