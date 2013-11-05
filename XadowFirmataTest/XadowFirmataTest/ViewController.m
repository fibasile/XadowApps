//
//  ViewController.m
//  XadowFirmataTest
//
//  Created by fiore on 05/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ViewController.h"
#import "XadowFirmata.h"
#import "XadowDevice.h"
#import "XadowUART.h"

@interface ViewController () <XadowRefreshDelegate>
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic,assign) BOOL connected;
@property (nonatomic,strong) XadowFirmata* firmata;
@property (nonatomic,assign) BOOL ledStatus;
@end

@implementation ViewController

-(void)awakeFromNib{
    self.connected = NO;
    self.statusLabel.text = @"Not connected";

}
-(void)xadowDidRefreshBLE:(XadowDevice *)sender {
    
    if (sender.uart){
        self.statusLabel.text = @"Connected";
        if (!self.connected){
            self.firmata = [[XadowFirmata alloc] initWithUART:sender.uart];
            [self.firmata startLoop];
//            [self startTests];
            self.connected = YES;
        }
    } else {
        self.statusLabel.text = @"Not connected";
    }
    
}

- (IBAction)queryFirmware:(id)sender {
    [self.firmata queryFirmware];

}
- (IBAction)queryLed:(id)sender{
    __block ViewController* _ctrl = self;
    [self.firmata queryLED:^(BOOL enabled) {
        NSLog( enabled ? @"Led enabled": @"Led Disabled");
        _ctrl.ledStatus = enabled;
    }];
}
-(IBAction)toggleLed:(id)sender{
    self.ledStatus= !self.ledStatus;
    [self.firmata toggleLED:self.ledStatus];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[XadowDevice shared] setDelegate:self];
    [[XadowDevice shared] startScanning];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
