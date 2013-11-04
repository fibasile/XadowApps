//
//  XadowUART.m
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "XadowUART.h"
#import "XadowDevice.h"


@implementation XadowUART


-(id)initWithXadowPeripheral:(CBPeripheral *)device {
    if (self = [super init]){
        self.device = device;
        self.device.delegate = self;
        self.writeCount = 0;
        self.readCount = 0;
        ADCircularBufferInit(&buffer,1024);
    }
    return self;
}



-(uint8_t)read {
    // read from circular buffer
    ElemType elem;
    ADCircularBufferRead(&buffer, &elem);
    return elem.value;
}

-(int)available {
    // check circular buffer
    return !ADCircularBufferIsEmpty(&buffer);
}

-(void)write:(uint8_t)byte {    
    if (self.cbReadWriteCharacteristic){
        NSData* data = [NSData dataWithBytes:&byte length:1];
        [self.device writeValue:data forCharacteristic:self.cbReadWriteCharacteristic type:CBCharacteristicWriteWithoutResponse];
        self.writeCount++;
    }
}

-(void)appendBuffer:(uint8_t)byte{
    // write to the tx characteritistic
    ElemType elem;
    elem.value =byte;
    ADCircularBufferWrite(&buffer, &elem);
}

-(CBUUID*)serviceUUID {
    return [CBUUID UUIDWithString:@"FFF0"];
}

-(CBUUID*)readUUID {
    return [CBUUID UUIDWithString:@"FFF2"];
}
-(CBUUID*)writeNotifyUUID {
    return [CBUUID UUIDWithString:@"FFF1"];
}


-(void)start {
    [self.device discoverServices:[NSArray arrayWithObject:self.serviceUUID]];
}
-(void)reset {
    if (self.device) {
        if (self.cbNotifyCharacteristic)
            [self.device setNotifyValue:NO forCharacteristic:self.cbNotifyCharacteristic];
        
        self.cbNotifyCharacteristic = nil;
        self.cbReadWriteCharacteristic = nil;
        [self.device setDelegate:nil];
        self.device = nil;
    }

}
- (void)dealloc
{
    if (self.device) {
        [self.device setDelegate:nil];
        self.device = nil;
    }
}


#pragma mark CBPeripheralDelegate

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
 // save the service
    if(error){
        // discover failed, so disconnect and bail out
        NSLog(@"Error discovering services %@",error.description);
        return;
    }
    
    
    // find serial service
    BOOL serviceFound = NO;
    for(CBService *c in peripheral.services){
        NSLog(@"Found service %@", c.UUID);
        if([c.UUID.data isEqual:self.serviceUUID.data]){
            // we're hit!
            self.service= c;
            serviceFound = YES;
            break;
        }
    }
    if(!serviceFound){
        // no service found, disconnect and bail out
        NSLog(@"No service found");
        //        NSError *notfoundError = [NSError errorWithDomain:kBLESerialServiceErrorDomain code:kBLESerialServiceErrorCodeNotFound userInfo:nil];
        return;
    }
    
    // service found, discovering the chars
    [self.device discoverCharacteristics:[NSArray arrayWithObjects:self.readUUID,self.writeNotifyUUID, nil] forService:self.service];

    
}
-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    // save the rsi
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    // find read rx and write tx characteristic
    // for read rx enable notification
    for (CBCharacteristic* c in service.characteristics){
        
        if ([c.UUID.data isEqual:self.readUUID.data]){
            NSLog(@"Found read character %@", c);

            self.cbReadWriteCharacteristic = c;
            
        }
        
        if ([c.UUID.data isEqual:self.writeNotifyUUID.data]){
            NSLog(@"Found write character %@", c);
            
            self.cbNotifyCharacteristic = c;
            
            [peripheral setNotifyValue:YES forCharacteristic:self.cbNotifyCharacteristic ];
            
        }
        
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
        // append to the circular buffer
    if([characteristic.UUID.data isEqual:self.writeNotifyUUID.data]){
     
        NSData* data = characteristic.value;
        self.readCount+=data.length;
        for (int i=0;i<data.length;i++){
            uint8_t byte;
            [data getBytes:&byte length:1];
            [self appendBuffer:byte];
        }
    
    }
    
}
@end
