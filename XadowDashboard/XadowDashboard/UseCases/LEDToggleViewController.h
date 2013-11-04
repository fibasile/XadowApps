//
//  LEDToggleViewController.h
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LEDToggleViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *ledSwitch;
@property (assign, nonatomic) BOOL ledStatus;
- (IBAction)toggleLedAction:(id)sender;

@end
