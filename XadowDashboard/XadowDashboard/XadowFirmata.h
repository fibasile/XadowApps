//
//  XadowFirmata.h
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XadowUART;

@interface XadowFirmata : NSObject

@property (nonatomic,strong) NSThread* bgThread;
@property (nonatomic,assign) XadowUART* uart;
@end
