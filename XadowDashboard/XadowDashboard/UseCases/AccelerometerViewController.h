//
//  AccelerometerViewController.h
//  XadowDashboard
//
//  Created by fiore on 11/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccelerometerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *eventButton;
@property (weak, nonatomic) IBOutlet UITextView *eventLog;

-(IBAction)evemtsAction:(id)sender;
@end
