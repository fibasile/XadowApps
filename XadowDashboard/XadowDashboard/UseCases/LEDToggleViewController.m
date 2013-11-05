//
//  LEDToggleViewController.m
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "LEDToggleViewController.h"
#import "XadowDevice.h"
#import "XadowFirmata.h"


@interface LEDToggleViewController ()
@property (nonatomic,retain) XadowFirmata* firmata;
@end

@implementation LEDToggleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)awakeFromNib {
    self.ledStatus = NO;
 
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    XadowUART* uart = [[XadowDevice shared] uart];
    
    if (uart!=nil){
    
        self.firmata = [[XadowFirmata alloc] initWithUART:uart];
        [self.firmata startLoop];
        [self.firmata queryLED:^(BOOL enabled){
            self.ledStatus = enabled;
            [self updateStatus];
        }];
        
        
    }
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.firmata)
        [self.firmata stopLoop];
    self.firmata = nil;
}


- (void)updateStatus {
    if (self.ledStatus){
        self.statusLabel.text = @"LED is On";
    } else {
        self.statusLabel.text = @"LED is Off";
    }
    
    [self.ledSwitch setOn:self.ledStatus];
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

- (IBAction)toggleLedAction:(id)sender {
    
    self.ledStatus = !self.ledStatus;
    [self updateStatus];
    [self.firmata toggleLED:self.ledStatus];
    
}
@end
