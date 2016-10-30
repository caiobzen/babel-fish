//
//  BFSettingsManager.m
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import "BFSettingsManager.h"


@interface BFSettingsManager ()

@property (strong, nonatomic) NSString *__myLocale;
@property (strong, nonatomic) NSString *__yourLocale;

@end

@implementation BFSettingsManager

@dynamic myLocale;
@dynamic yourLocale;

+ (instancetype)settings
{
    static dispatch_once_t onceToken;
    static BFSettingsManager *settings;
    dispatch_once(&onceToken, ^{
        settings = [BFSettingsManager new];
    });
    
    return settings;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"myLocale" : @"en", @"yourLocale" : @"pt"}];
    }
    return self;
}

- (NSString *)myLocale
{
    if(!self.__myLocale)
        self.__myLocale = [[NSUserDefaults standardUserDefaults] valueForKey:@"myLocale"];
    return self.__myLocale;
}

- (NSString *)yourLocale
{
    if(!self.__yourLocale)
        self.__yourLocale = [[NSUserDefaults standardUserDefaults] valueForKey:@"yourLocale"];
    return self.__yourLocale;
}
- (void)setMyLocale:(NSString *)myLocale
{
    [[NSUserDefaults standardUserDefaults] setValue:myLocale forKey:@"myLocale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.__myLocale = myLocale;
}

- (void)setYourLocale:(NSString *)yourLocale
{
    [[NSUserDefaults standardUserDefaults] setValue:yourLocale forKey:@"yourLocale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.__yourLocale = yourLocale;
}

+ (NSString *)languageForLocale:(NSString *)locale
{
        NSDictionary *identifiers = @{
                            @"pt":@"Portuguese",
                            @"en":@"English",
                            @"zh":@"Chinese",
                            @"nl":@"Dutch",
                            @"fr":@"French",
                            @"de":@"German",
                            @"it":@"Italian",
                            @"ja":@"Japanese",
                            @"ko":@"Korean",
                            @"pl":@"Polish",
                            @"ro":@"Romanian",
                            @"ru":@"Russian",
                            @"sk":@"Slovak",
                            @"es":@"Spanish",
                            @"sv":@"Swedish",
                            @"th":@"Thai",
                            @"tr":@"Turkish",
                            @"uk":@"Ukrainian"
                            };
    return identifiers[locale];
}

@end
