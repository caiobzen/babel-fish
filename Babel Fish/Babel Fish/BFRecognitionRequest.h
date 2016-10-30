//
//  BFRecognitionRequest.h
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BFRecognitionRequestHandler)(NSString *);

@interface BFRecognitionRequest : NSObject
//+ (void)detectLanguage:(NSString *)phrase handler:(BFRecognitionRequestHandler)handler;
+ (void)translatePhrase:(NSString *)phrase from:(NSString *)from to:(NSString *)to handler:(BFRecognitionRequestHandler)handler;
@end
