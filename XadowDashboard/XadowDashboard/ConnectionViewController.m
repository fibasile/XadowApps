//
//  ConnectionViewController.m
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ConnectionViewController.h"
#import "XadowDevice.h"

@interface ConnectionViewController () <XadowRefreshDelegate>

@end

@implementation ConnectionViewController

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
    [[XadowDevice shared] setDelegate:self];
    [[XadowDevice shared] startScanning];
   

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)xadowDidRefreshBLE:(XadowDevice *)sender {
    
    NSLog(@"Did refresh ble");
    if (!sender.canScan) {
      self.connectionStatus.text = @"BLE not supported";
    } else if (sender.connectedServices.count > 0) {
        self.connectionStatus.text = @"Connected";
    }else {
        self.connectionStatus.text = @"Not connected";
    }
}
@end
