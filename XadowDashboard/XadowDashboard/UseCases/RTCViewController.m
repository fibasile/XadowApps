//
//  RTCViewController.m
//  XadowDashboard
//
//  Created by fiore on 11/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "RTCViewController.h"
#import "XadowDevice.h"
#import "XadowFirmata.h"
@interface RTCViewController ()
@property (nonatomic,retain) XadowFirmata* firmata;

@end

@implementation RTCViewController

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
    
    XadowUART* uart = [[XadowDevice shared] uart];
    
    if (uart!=nil){
        self.firmata = [[XadowFirmata alloc] initWithUART:uart];
        [self.firmata startLoop];
    }
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

- (IBAction)setTime:(id)sender {

    NSDate* now = [NSDate date];
    NSCalendar* cal = [NSCalendar currentCalendar];
    [cal setTimeZone:[NSTimeZone defaultTimeZone]];
    NSDateComponents* comps = [cal components:NSCalendarUnitYear|NSCalendarUnitWeekdayOrdinal|NSCalendarUnitMonth|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitHour|NSCalendarUnitDay fromDate:now];
    int year = comps.year - 2000;
    int month = comps.month;
    int day = comps.day;
    int hour = comps.hour;
    int minute = comps.minute;
    int second = comps.second;
    int dayOfWeek = comps.weekdayOrdinal == 1 ? 7 : comps.weekdayOrdinal - 1 ;

    NSLog(@"%d/%d/%d %d %d:%d:%d", year,month,day,dayOfWeek,hour,minute,second);
    
    [self.firmata setTimeWithYear:year month:month day:day weekDay:dayOfWeek hour:hour minutes:minute seconds:second];
    
    
}

- (IBAction)displayTime:(id)sender {
    
    [self.firmata displayTime];
    
}
@end
