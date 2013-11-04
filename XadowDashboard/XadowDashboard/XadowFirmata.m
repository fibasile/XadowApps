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




@interface XadowFirmata ()

@property (nonatomic,assign)BOOL parsingSysEx;
@property (nonatomic,assign)int waitForData;
@property (nonatomic,strong)NSMutableData* receivedBuffer;
@property (nonatomic,assign)int executeMultiByteCommand;

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
    [self.receivedBuffer getBytes:&firstByte length:1];
    
    
    if (firstByte == REPORT_FIRMWARE) {
        
        [self parseSysexReportFirmware];
        
    } else {
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

@end
