//
//  XadowFirmata.h
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>



// acceleration events
#define ADXL345_SINGLE_TAP 0x06
#define ADXL345_DOUBLE_TAP 0x05
#define ADXL345_ACTIVITY   0x04
#define ADXL345_INACTIVITY 0x03
#define ADXL345_FREE_FALL  0x02
#define ADXL345_WATERMARK  0x01
#define ADXL345_OVERRUNY   0x00


@class XadowUART;

@interface XadowFirmata : NSObject

@property (nonatomic,strong) NSThread* bgThread;
@property (nonatomic,strong) XadowUART* uart;

- (id)initWithUART:(XadowUART*)uart;
-(void)queryFirmware;
-(void) toggleLED:(BOOL)on;
-(void)queryLED:(void(^)(BOOL enabled))block;
- (void) queryBattery:(void(^)(uint8_t chargeStatus, float charge))chargeVlock;
- (void)updateDisplay:(NSString*)text;
- (void)resetDisplay;
- (void)queryAccelerometer:(void(^)(uint8_t accel_event))accelBlock;
- (void)toggleAccelerometer:(BOOL)onOff;
- (void)setTimeWithYear:(int)year month:(int)month day:(int)day weekDay:(int)weekDay hour:(int)hour minutes:(int)minutes seconds:(int)seconds;
- (void)displayTime;
- (void) startLoop;
-(void) stopLoop;
@end
