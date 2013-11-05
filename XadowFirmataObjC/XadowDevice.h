//
//  XadowPeripheral.h
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "XadowUART.h"

@protocol XadowRefreshDelegate

-(void)xadowDidRefreshBLE:(XadowDevice*)sender;

@end


@interface XadowDevice : NSObject <CBCentralManagerDelegate>

@property (nonatomic,strong) CBCentralManager* centralManager;
@property (retain, nonatomic) NSMutableArray    *foundPeripherals;
@property (retain, nonatomic) NSMutableArray    *connectedServices;
@property (nonatomic,assign) id<XadowRefreshDelegate> delegate;
@property (nonatomic,assign) BOOL canScan;
@property (nonatomic,readonly) CBUUID* deviceUUID;
@property (nonatomic,readonly) NSArray* servicesUUID;
+(XadowDevice*)shared;
-(void)startScanning;
-(void)stopScanning;
-(XadowUART*)uart;

@end
