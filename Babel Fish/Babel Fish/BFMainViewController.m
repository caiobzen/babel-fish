//
//  BFMainViewController.m
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import "BFConstants.h"
#import "BFMainViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface BFMainViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) IBOutlet UITextView *textView;

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@end

@implementation BFMainViewController

- (NSString *) soundFilePath {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    return [docsDir stringByAppendingPathComponent:@"sound.caf"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:[self soundFilePath]];
    NSDictionary *recordSettings = @{
        AVEncoderAudioQualityKey:@(AVAudioQualityMin),
        AVEncoderBitRateKey: @16,
        AVNumberOfChannelsKey: @1,
        AVSampleRateKey: @(BFAudioSampleRate)
    };
    
    NSError *error;
    _audioRecorder = [[AVAudioRecorder alloc]
                      initWithURL:soundFileURL
                      settings:recordSettings
                      error:&error];
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
    }
}

- (IBAction)recordAudio:(id)sender {
    [self stopAudio:sender];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [_audioRecorder record];
}

- (IBAction)playAudio:(id)sender {
    [self stopAudio:sender];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc]
                    initWithContentsOfURL:_audioRecorder.url
                    error:&error];
    _audioPlayer.delegate = self;
    _audioPlayer.volume = 1.0;
    if (error)
        NSLog(@"Error: %@",
              error.localizedDescription);
    else
        [_audioPlayer play];
}

- (IBAction)stopAudio:(id)sender {
    if (_audioRecorder.recording) {
        [_audioRecorder stop];
    } else if (_audioPlayer.playing) {
        [_audioPlayer stop];
    }
}

- (IBAction) processAudio:(id) sender {
    [self stopAudio:sender];
    
    NSString *service = @"https:/speech.googleapis.com/v1beta1/speech:syncrecognize";
    service = [service stringByAppendingString:@"?key="];
    service = [service stringByAppendingString:BFSpeechRecognitionKey];
    
    NSData *audioData = [NSData dataWithContentsOfFile:[self soundFilePath]];
    NSDictionary *configRequest = @{@"encoding":@"LINEAR16",
                                    @"sampleRate":@(BFAudioSampleRate),
                                    @"maxAlternatives":@30};
    NSDictionary *audioRequest = @{@"content":[audioData base64EncodedStringWithOptions:0]};
    NSDictionary *requestDictionary = @{@"config":configRequest,
                                        @"audio":audioRequest};
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                          options:0
                                                            error:&error];
    
    NSString *path = service;
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    // if your API key has a bundle ID restriction, specify the bundle ID like this:
    [request addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-Ios-Bundle-Identifier"];
    NSString *contentType = @"application/json";
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:@"POST"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                             completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             _textView.text = stringResult;
             NSLog(@"RESULT: %@", stringResult);
         });
     }];
    [task resume];
}

# pragma mark - Actions

- (IBAction)startRecording:(UIButton *)sender
{
    
}

- (IBAction)stopRecording:(UIButton *)sender
{
    
}

@end
