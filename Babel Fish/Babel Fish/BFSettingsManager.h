//
//  BFSettingsManager.h
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFSettingsManager : NSObject
@property (strong, nonatomic) NSString *myLocale;
@property (strong, nonatomic) NSString *yourLocale;

+ (instancetype)settings;

+ (NSString *)languageForLocale:(NSString *)locale;

@end
