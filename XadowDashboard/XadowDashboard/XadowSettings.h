//
//  XadowSettings.h
//  XadowDashboard
//
//  Created by fiore on 04/11/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XadowSettings : NSObject
+(XadowSettings*)shared;

@property (nonatomic,strong) NSMutableDictionary* settings;
@property (nonatomic,readonly) NSArray* keys;
-(BOOL)updateSetting:(BOOL)onOff forKey:(NSString*)key;
@end
