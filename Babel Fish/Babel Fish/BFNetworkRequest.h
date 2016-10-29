//
//  BFNetworkRequest.h
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BFRequestType) {
    BFRequestTypeGet,
    BFRequestTypePost,
    BFRequestTypePut,
    BFRequestTypeDelete
};

typedef void(^BFRequestHandler)(id response, NSError *error);

@interface BFNetworkRequest : NSObject
+ (void)getWithURL:(NSString *)URL handler:(BFRequestHandler)handler;
+ (void)postWithURL:(NSString *)URL data:(NSData *)requestData handler:(BFRequestHandler)handler;
+ (void)putWithURL:(NSString *)URL data:(NSData *)requestData handler:(BFRequestHandler)handler;
+ (void)deleteWithURL:(NSString *)URL data:(NSData *)requestData handler:(BFRequestHandler)handler;
@end
