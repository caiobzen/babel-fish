//
//  BFSettingsViewController.m
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import "BFSettingsViewController.h"
#import "BFSettingsManager.h"
#import <YOLOKit/YOLO.h>

@interface BFSettingsViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak  , nonatomic) IBOutlet UIPickerView *myLocalePicker;
@property (weak  , nonatomic) IBOutlet UIPickerView *yourLocalePicker;
@property (strong, nonatomic) NSDictionary *allLanguages;
@property (strong, nonatomic) NSDictionary *allIdentifiers;
@property (strong, nonatomic) NSArray *languages;
@end

@implementation BFSettingsViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(!_languages) {
        _languages = @[
                       @"Portuguese",
                       @"English",
                       @"Chinese",
                       @"Dutch",
                       @"French",
                       @"German",
                       @"Italian",
                       @"Japanese",
                       @"Korean",
                       @"Polish",
                       @"Romanian",
                       @"Russian",
                       @"Slovak",
                       @"Spanish",
                       @"Swedish",
                       @"Thai",
                       @"Turkish",
                       @"Ukrainian"
                       ];
    }
    
    [self buildPickers];
}

- (void)buildPickers
{
    NSString *myLocale = [BFSettingsManager settings].myLocale;
    [self buildPicker:self.myLocalePicker withLocaleIdentifier:myLocale];
    
    NSString *yourLocale = [BFSettingsManager settings].yourLocale;
    [self buildPicker:self.yourLocalePicker withLocaleIdentifier:yourLocale];
}

- (void)buildPicker:(UIPickerView *)picker withLocaleIdentifier:(NSString *)identifier
{
    picker.delegate   = self;
    picker.dataSource = self;
    
    NSString *key = self.allIdentifiers[identifier];
    NSInteger index = [self.languages indexOfObject:key];
    [picker selectRow:index inComponent:0 animated:YES];
}

# pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.languages.count;
}

# pragma mark - UIPickerViewDelegate

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.languages[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *languageKey = self.languages[row];
    NSString *identifier  = self.allLanguages[languageKey];
    
    if(pickerView == self.myLocalePicker) {
        [BFSettingsManager settings].myLocale = identifier;
        
        return;
    }
    
    if(pickerView == self.yourLocalePicker) {
        [BFSettingsManager settings].yourLocale = identifier;
        return;
    }
}

# pragma mark - Accessors

- (NSDictionary *)allLanguages
{
    if(!_allLanguages) {
        _allLanguages = @{
                          @"Portuguese":@"pt",
                          @"English":@"en",
                          @"Chinese":@"zh",
                          @"Dutch":@"nl",
                          @"French":@"fr",
                          @"German":@"de",
                          @"Italian":@"it",
                          @"Japanese":@"ja",
                          @"Korean":@"ko",
                          @"Polish":@"pl",
                          @"Romanian":@"ro",
                          @"Russian":@"ru",
                          @"Slovak":@"sk",
                          @"Spanish":@"es",
                          @"Swedish":@"sv",
                          @"Thai":@"th",
                          @"Turkish":@"tr",
                          @"Ukrainian":@"uk"
                          };
    }
    return _allLanguages;
}

- (NSDictionary *)allIdentifiers
{
    if(!_allIdentifiers) {
        _allIdentifiers = @{
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
    }
    return _allIdentifiers;
}


//
// Helpers
//

- (NSInteger)indexOfIdentifier2:(NSString *)identifier
{
    NSInteger index = self.allLanguages.allValues.indexOf(identifier);
    return index != NSNotFound ? index : 0;
}

@end
