//
//  BFSettingsManager.h
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFSettingsManager : NSObject
@property (strong, nonatomic) NSLocale *language;

+ (instancetype)settings;

@end
