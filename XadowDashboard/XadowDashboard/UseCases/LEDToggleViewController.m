//
//  LEDToggleViewController.m
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "LEDToggleViewController.h"

@interface LEDToggleViewController ()

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
       [self updateStatus];
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
    
}
@end
