//
//  BFNetworkRequest.m
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import "BFNetworkRequest.h"

@implementation BFNetworkRequest

+ (void)getWithURL:(NSString *)URL handler:(BFRequestHandler)handler {
    [self requestType:BFRequestTypeGet url:URL data:nil handler:handler];
}

+ (void)postWithURL:(NSString *)URL data:(NSData *)requestData handler:(BFRequestHandler)handler
{
    [self requestType:BFRequestTypePost url:URL data:requestData handler:handler];
}

+ (void)putWithURL:(NSString *)URL data:(NSData *)requestData handler:(BFRequestHandler)handler
{
    [self requestType:BFRequestTypePut url:URL data:requestData handler:handler];
}

+ (void)deleteWithURL:(NSString *)URL data:(NSData *)requestData handler:(BFRequestHandler)handler
{
    [self requestType:BFRequestTypeDelete url:URL data:requestData handler:handler];
}

+ (void)requestType:(BFRequestType)type url:(NSString *)URL data:(NSData *)data handler:(BFRequestHandler)handler
{
    NSURL *theURL = [NSURL URLWithString:URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:theURL];
    [request setHTTPMethod: [self methodType:type]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-Ios-Bundle-Identifier"];
    
    if(data) {
        [request setHTTPBody:data];
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                id json = nil;
                if(data) {
                    json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                }
                handler(json, error);
            });
        }] resume];
}

//
// Helpers
//

+ (NSString *)methodType:(BFRequestType)type
{
    switch(type) {
        case BFRequestTypeGet:    return @"GET";
        case BFRequestTypePost:   return @"POST";
        case BFRequestTypePut:    return @"PUT";
        case BFRequestTypeDelete: return @"DELETE";
    }
}

@end
