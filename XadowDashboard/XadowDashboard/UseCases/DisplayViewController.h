//
//  DisplayViewController.h
//  XadowDashboard
//
//  Created by fiore on 05/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DisplayViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *displayText;
- (IBAction)sendText:(id)sender;
- (IBAction)resetDisplay:(id)sender;

@end
