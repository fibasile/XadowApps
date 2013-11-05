//
//  BatteryViewController.m
//  XadowDashboard
//
//  Created by fiore on 05/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "BatteryViewController.h"
#import "XadowDevice.h"
#import "XadowFirmata.h"
@interface BatteryViewController ()
@property (nonatomic,retain) XadowFirmata* firmata;
@end

@implementation BatteryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    XadowUART* uart = [[XadowDevice shared] uart];
    
    if (uart!=nil){
        
        self.firmata = [[XadowFirmata alloc] initWithUART:uart];
        [self.firmata startLoop];
        [self.firmata queryBattery:^(uint8_t chargeStatus, uint8_t charge) {
        
            
            NSString* statusString = @"reading...";
            
            switch (chargeStatus) {
                case 0x01:
                    statusString = @"Charging";
                    break;
                case 0x02:
                    statusString = @"Fully charged";
                    break;
                default:
                    statusString = @"Draining";
                    break;
            }
            
            
            self.statusLabel.text = statusString;
            
            self.chargeLabel.text = [NSString stringWithFormat:@"%d",charge];
            
        }];
        
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.firmata)
        [self.firmata stopLoop];
    self.firmata = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
