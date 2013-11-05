//
//  BatteryViewController.h
//  XadowDashboard
//
//  Created by fiore on 05/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BatteryViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *chargeLabel;

@end
