//
//  BFSettingsManager.m
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import "BFSettingsManager.h"

@implementation BFSettingsManager

+ (instancetype)settings
{
    static dispatch_once_t onceToken;
    static BFSettingsManager *settings;
    dispatch_once(&onceToken, ^{
        settings = [BFSettingsManager new];
    });
    
    return settings;
}

- (NSString *)myLocale
{
    return @"en";
}

- (NSString *)yourLocale
{
    return @"pt";
}

@end
