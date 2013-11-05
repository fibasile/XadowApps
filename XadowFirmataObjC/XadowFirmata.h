//
//  XadowFirmata.h
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XadowUART;

@interface XadowFirmata : NSObject

@property (nonatomic,strong) NSThread* bgThread;
@property (nonatomic,strong) XadowUART* uart;

- (id)initWithUART:(XadowUART*)uart;
-(void)queryFirmware;
-(void) toggleLED:(BOOL)on;
-(void)queryLED:(void(^)(BOOL enabled))block;
- (void) queryBattery:(void(^)(uint8_t chargeStatus, uint8_t charge))chargeVlock;
- (void)updateDisplay:(NSString*)text;
- (void)resetDisplay;
- (void) startLoop;
-(void) stopLoop;
@end
