//
//  DisplayViewController.m
//  XadowDashboard
//
//  Created by fiore on 05/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "DisplayViewController.h"
#import "XadowDevice.h"
#import "XadowFirmata.h"
@interface DisplayViewController ()
@property (nonatomic,retain) XadowFirmata* firmata;
@end

@implementation DisplayViewController

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

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)sendText:(id)sender {
    NSString* text = self.displayText.text;
    text =[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length)
        [self.firmata updateDisplay:text];

}

- (IBAction)resetDisplay:(id)sender {
    [self.firmata resetDisplay];
}
@end
