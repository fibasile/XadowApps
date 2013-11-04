//
//  XadowPeripheral.m
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "XadowDevice.h"

static XadowDevice* _xadow;

@implementation XadowDevice

+(XadowDevice*)shared{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _xadow = [[XadowDevice alloc] init];
    });
    return _xadow;
}


- (id)init
{
    self = [super init];
    if (self) {
        NSDictionary* opts = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],CBCentralManagerOptionShowPowerAlertKey,
                              @"xadow.central",CBCentralManagerOptionRestoreIdentifierKey
                              , nil];
        
        self.canScan = NO;
        NSLog(@"Central Manager init");
        self.connectedServices = [NSMutableArray array];
        self.foundPeripherals = [NSMutableArray array];
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:opts];
    }
    return self;
}

- (void) dealloc
{
    // We are a singleton and as such, dealloc shouldn't be called.
    assert(NO);
}



-(CBUUID*) deviceUUID {
    return [CBUUID UUIDWithString:@"58808941-83FE-473C-F95D-340B6DA1272B"];
}
-(NSArray*) servicesUUID {
    return [NSArray arrayWithObject:[CBUUID UUIDWithString:@"fff0"]];
}


-(void)notifyDelegate {
    if (self.delegate){
        [self.delegate xadowDidRefreshBLE:self];
    }
}

#pragma mark Known devices cache

-(void)loadSavedDevice {
    
    NSArray *storedDevices  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    if (![storedDevices isKindOfClass:[NSArray class]]) {
        NSLog(@"No stored array to load");
        return;
    }
    
    for (id deviceUUIDString in storedDevices) {
        
        if (![deviceUUIDString isKindOfClass:[NSString class]])
            continue;
        
        NSUUID* uuid = [[NSUUID alloc] initWithUUIDString:deviceUUIDString];
        if (!uuid)
            continue;
        
        [self.centralManager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:(id)uuid]];
    }
    
}


- (void) saveDeviceWithIdentifier:(NSUUID*) uuid
{
    NSArray         *storedDevices  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    NSMutableArray  *newDevices     = nil;
    
    if (![storedDevices isKindOfClass:[NSArray class]]) {
        NSLog(@"Can't find/create an array to store the uuid");
        storedDevices = [NSArray array];
    }
    
    newDevices = [NSMutableArray arrayWithArray:storedDevices];
    
    [newDevices addObject:uuid.description];
    /* Store */
    [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"StoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void) removeSavedDevice:(NSUUID*) uuid
{
    NSArray         *storedDevices  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
    NSMutableArray  *newDevices     = nil;

    
    if ([storedDevices isKindOfClass:[NSArray class]]) {
        newDevices = [NSMutableArray arrayWithArray:storedDevices];
        
        [newDevices removeObject:uuid];
        /* Store */
        [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"StoredDevices"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark action

-(XadowUART*)uart {
    
    if (self.connectedServices.count > 0){
        return (XadowUART*)[self.connectedServices lastObject];
    }
    return nil;
}

-(void)startScanning {
    NSLog(@"Start scanning..");
        NSDictionary    *options    = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [self.centralManager scanForPeripheralsWithServices:nil options:options];
   
}
- (void) stopScanning
{
    [self.centralManager stopScan];
}


- (void) clearDevices
{
    [self.foundPeripherals removeAllObjects];
    
    for (XadowUART* service in self.connectedServices) {
        [service reset];
    }
    [self.connectedServices removeAllObjects];
}


- (void) connectPeripheral:(CBPeripheral*)peripheral
{
    if ([peripheral state] != CBPeripheralStateConnected || [peripheral state] != CBPeripheralStateConnecting) {
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}


- (void) disconnectPeripheral:(CBPeripheral*)peripheral
{
    [self.centralManager cancelPeripheralConnection:peripheral];
}





#pragma mark CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"Updated state");
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        self.canScan = YES;
        [self loadSavedDevice];
        [central retrieveConnectedPeripheralsWithServices:self.servicesUUID];
        
        
    }  else if (central.state < CBCentralManagerStatePoweredOn) {
            //  scanning has stopped and that any connected peripherals have been disconnected
             [self clearDevices];
    } else if (central.state <= CBCentralManagerStatePoweredOff ) {
             [self clearDevices];
            // cbcentral manager is not ready or not available
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This device doesn't support BLE, or app is not authorized to use it" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [alert show];
        
    }
    [self notifyDelegate];
    
}

-(void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    CBPeripheral    *peripheral;
    
    /* Add to list. */
    for (peripheral in peripherals) {
        [self connectPeripheral:peripheral];
    }
    
    [self notifyDelegate];
}

-(void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    CBPeripheral    *peripheral;
    
    /* Add to list. */
    for (peripheral in peripherals) {
        [self connectPeripheral:peripheral];
    }
    [self notifyDelegate];
    
}

-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    
    
}


-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Did discover peripheral %@", peripheral);
    
    if (![self.foundPeripherals containsObject:peripheral]) {
        [self.foundPeripherals addObject:peripheral];
        [self notifyDelegate];
        if ([[CBUUID UUIDWithNSUUID:peripheral.identifier].data isEqual:self.deviceUUID.data]){
            NSLog(@"Found xadow");
            [self connectPeripheral:peripheral];
        }
    }
    
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
      NSLog(@"Attempted connection to peripheral %@ failed: %@", [peripheral name], [error localizedDescription]);
    [self removeSavedDevice:peripheral.identifier];
    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    [self saveDeviceWithIdentifier:peripheral.identifier];

    NSLog(@"xadow connected");

    XadowUART   *service    = nil;
    
    /* Create a service instance. */
    service = [[XadowUART alloc] initWithXadowPeripheral:peripheral ];
    [service start];
    
    if (![self.connectedServices containsObject:service])
        [self.connectedServices addObject:service];
    
    if ([self.foundPeripherals containsObject:peripheral])
        [self.foundPeripherals removeObject:peripheral];
    

    [self notifyDelegate];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    XadowUART   *service    = nil;
    
    NSLog(@"xadow disconnected");
    
    for (service in self.connectedServices) {
        if ([service device] == peripheral) {
            [self.connectedServices removeObject:service];
            break;
        }
    }
    
    [self notifyDelegate];
    
}


 
@end
