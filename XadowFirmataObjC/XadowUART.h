//
//  XadowUART.h
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ADCircularBuffer.h"

@class XadowDevice;

@interface XadowUART : NSObject <CBPeripheralDelegate> {
    ADCircularBuffer buffer;
}

@property (nonatomic,strong) CBPeripheral* device;
@property (nonatomic,strong) CBService* service;
@property (nonatomic,readonly) CBUUID* serviceUUID;
@property (nonatomic,readonly) CBUUID* readUUID;
@property (nonatomic,readonly) CBUUID* writeNotifyUUID;
@property(strong,nonatomic) CBCharacteristic *cbReadWriteCharacteristic;
@property(strong,nonatomic) CBCharacteristic *cbNotifyCharacteristic;

@property (nonatomic,assign)int writeCount;
@property (nonatomic,assign)int readCount;

-initWithXadowPeripheral:(CBPeripheral*)device;


-(uint8_t)read;
-(int)available;
-(void)write:(uint8_t*)bytes length:(int)len;

-(void)reset;
-(void)start;

@end
