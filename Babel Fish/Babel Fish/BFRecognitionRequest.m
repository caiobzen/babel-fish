//
//  BFRecognitionRequest.m
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import "BFConstants.h"
#import "BFRecognitionRequest.h"
#import "BFNetworkRequest.h"

@implementation BFRecognitionRequest

//+ (void)detectLanguage:(NSString *)phrase handler:(BFRecognitionRequestHandler)handler
//{
//    NSMutableString *url = [NSMutableString string];
//    [url appendString:@"https://www.googleapis.com/language/translate/v2/detect"];
//    [url appendFormat:@"?key=%@", BFGoogleApiKey];
//    [url appendFormat:@"&q=%@", [phrase stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
//    
//    [BFNetworkRequest getWithURL:url handler:^(id detectJSON, NSError *error) {
//        if(detectJSON) {
//            NSArray *alternatives = detectJSON[@"data"][@"detections"];
//            NSString *source = [(NSDictionary *)alternatives[0][0] objectForKey:@"language"];
//            handler(source);
//        } else {
//            NSLog(@"ERROR ON DETECT");
//        }
//    }];
//}

+ (void)translatePhrase:(NSString *)phrase from:(NSString *)from to:(NSString *)to handler:(BFRecognitionRequestHandler)handler
{
    NSMutableString *translate = [NSMutableString string];
    [translate appendString:@"https://www.googleapis.com/language/translate/v2"];
    [translate appendFormat:@"?key=%@", BFGoogleApiKey];
    [translate appendFormat:@"&source=%@", from];
    [translate appendFormat:@"&target=%@", to];
    [translate appendFormat:@"&q=%@", [phrase stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [BFNetworkRequest getWithURL:translate handler:^(id translateJSON, NSError *error) {
        if(translateJSON) {
            NSString *phrase = translateJSON[@"data"][@"translations"][0][@"translatedText"];
            handler(phrase);
        } else {
            NSLog(@"ERROR ON TRANSLATE");
        }
    }];

}

@end
