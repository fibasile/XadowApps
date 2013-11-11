//
//  AccelerometerViewController.m
//  XadowDashboard
//
//  Created by fiore on 11/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "AccelerometerViewController.h"
#import "XadowDevice.h"
#import "XadowFirmata.h"
@interface AccelerometerViewController ()
@property (nonatomic,retain) XadowFirmata* firmata;
@property (nonatomic,assign) BOOL active;
@end

@implementation AccelerometerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.active = NO;
    self.eventLog.text = @"";
    
    XadowUART* uart = [[XadowDevice shared] uart];
    
    if (uart!=nil){
        self.firmata = [[XadowFirmata alloc] initWithUART:uart];
        [self.firmata startLoop];
    }
}


-(void)evemtsAction:(id)sender {
    if (!self.active){
            [self startEvents:sender];
    } else {
            [self stopEvents:sender];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.active){
        [self stopEvents:self];
    }
}

-(void)startEvents:(id)sender {
    [self.eventButton setTitle:@"Disable events" forState:UIControlStateNormal];
    self.active = YES;
    self.eventLog.text = @"";
    [self.firmata queryAccelerometer:^(uint8_t accel_event) {
        [self logEvent:accel_event];
    }];
    [self.firmata toggleAccelerometer:YES];
    

}

-(void)stopEvents:(id)sender {
    [self.firmata toggleAccelerometer:NO];
    self.active = NO;
    [self.eventButton setTitle:@"Enable events" forState:UIControlStateNormal];
}

- (NSString*) evtTypeToString:(int)event_type {
    NSString* eventString = @"Unknown";
    switch (event_type) {
        case ADXL345_SINGLE_TAP:
            eventString = @"Single tap";
            break;
        case ADXL345_DOUBLE_TAP:
            eventString = @"Double tap";
            break;
        case ADXL345_ACTIVITY:
            eventString = @"Activity";
            break;
        case ADXL345_INACTIVITY:
            eventString = @"Inactivity";
            break;
        case ADXL345_FREE_FALL:
            eventString = @"Free fall";
            break;
        default:
            break;
    }
    return eventString;
}


- (void) logEvent:(int)evt_type{
    NSString* evtString = [self evtTypeToString:evt_type];
    self.eventLog.text = [NSString stringWithFormat:@"%@\n%@", evtString, self.eventLog.text];
    [self.eventLog scrollRangeToVisible:NSMakeRange(0, 1)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
