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
@property (weak  , nonatomic) IBOutlet UITextField *nameField;
@property (weak  , nonatomic) IBOutlet UIPickerView *languagePickerView;
@property (weak  , nonatomic) IBOutlet UIPickerView *otherLanguagePickerView;
@property (strong, nonatomic) NSDictionary *allLanguages;
@end

@implementation BFSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.languagePickerView.delegate   = self;
    self.languagePickerView.dataSource = self;
    
    NSLocale *locale = [BFSettingsManager settings].language;
    
    if(locale) {
        NSInteger index = self.allLanguages.allValues.map(^(NSLocale *locale){
            return locale.localeIdentifier;
        }).indexOf(locale.localeIdentifier);
   
        [self.languagePickerView selectRow:index inComponent:0 animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.allLanguages.allKeys.count;
}

- (NSDictionary *)allLanguages
{
    if(!_allLanguages) {
        _allLanguages = ([NSLocale availableLocaleIdentifiers] ?: @[]).map(^(NSString *language){
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:language];
            NSString *displayName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:language];
            
            return @[displayName, locale];
        }).dict;
    }
    
    return _allLanguages;
}

# pragma mark - UIPickerViewDelegate

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.allLanguages.allKeys[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *languageKey    = self.allLanguages.allKeys[row];
    NSLocale *selectedLocale = self.allLanguages[languageKey];
    [[BFSettingsManager settings] setLanguage:selectedLocale];
}

@end
