//
//  XadowSettings.m
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "XadowSettings.h"

static XadowSettings* _sharedSettings=nil;

@implementation XadowSettings

+(XadowSettings *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSettings = [[XadowSettings alloc] init];
    });
    return _sharedSettings;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.settings = [NSMutableDictionary dictionary];
        [self initDefaults];
    }
    return self;
}

- (NSArray*) keys {
    return @[@"Display",@"BLE",@"Accelerometer",@"Adaptor",@"Breakout",@"Buzzer",@"Compass",@"IMU",@"GPS",@"Grove", @"Motor", @"NFC", @"Storage", @"UV Sensor", @"Vibration"];
}


- (void) initDefaults {
    [self.settings setObject:@YES forKey:@"Display"];
    [self.settings setObject:@YES forKey:@"BLE"];
    [self.settings setObject:@NO forKey:@"Accelerometer"];
    [self.settings setObject:@NO forKey:@"Adaptor"];
    [self.settings setObject:@NO forKey:@"Breakout"];
    [self.settings setObject:@NO forKey:@"Buzzer"];
    [self.settings setObject:@NO forKey:@"Compass"];
    [self.settings setObject:@NO forKey:@"IMU"];
    [self.settings setObject:@NO forKey:@"GPS"];
    [self.settings setObject:@NO forKey:@"Grove"];
    [self.settings setObject:@NO forKey:@"Motor"];
    [self.settings setObject:@NO forKey:@"NFC"];
    [self.settings setObject:@NO forKey:@"Storage"];
    [self.settings setObject:@NO forKey:@"UV Sensor"];
    [self.settings setObject:@NO forKey:@"Vibration"];
}

-(BOOL)updateSetting:(BOOL)onOff forKey:(NSString*)key {
    if (!onOff && [key isEqualToString:@"BLE"]){
        return NO;
    }
    [self.settings setObject:[NSNumber numberWithBool:onOff] forKey:key];
    return YES;
}


@end
