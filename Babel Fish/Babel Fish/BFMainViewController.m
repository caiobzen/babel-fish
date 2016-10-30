//
//  BFMainViewController.m
//  Babel Fish
//
//  Created by Rafael Ramos on 10/29/16.
//  Copyright © 2016 Isobar Hackathon. All rights reserved.
//

#import "BFMainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>
#import "BFConstants.h"
#import "BFSettingsManager.h"
#import "BFRecognitionRequest.h"
#import "SCSiriWaveformView.h"

@interface BFMainViewController () <AVCaptureAudioDataOutputSampleBufferDelegate>
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynt;
@property (strong, nonatomic) SFSpeechRecognitionTask *recognitionTask;
@property (strong, nonatomic) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) AVCaptureSession *capture;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;
@property (weak, nonatomic) IBOutlet UIButton *otherTalkButton;
@property (weak, nonatomic) IBOutlet UIButton *meTalkButton;
@property (weak, nonatomic) IBOutlet UIView *activityView;
@property (weak, nonatomic) IBOutlet UIView *recordingView;
@property (strong, nonatomic) SCSiriWaveformView *waveform;
@property (strong, nonatomic) NSTimer *waveTimer;

@end

@implementation BFMainViewController

# pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self prepareRecord];
    [self roundSomeCorners];
}

- (void)prepareRecord {

    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
    }];
}

# pragma mark - Audio Processing

- (void)recordAudio:(NSString *)language speakIn:(NSString *)speakLanguage {
    
    __weak __typeof(self) welf = self;
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        if (status == SFSpeechRecognizerAuthorizationStatusAuthorized){
            NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:language];
            SFSpeechRecognizer *sf =[[SFSpeechRecognizer alloc] initWithLocale:local];
            welf.speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
            [sf recognitionTaskWithRequest:welf.speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
                
                if(result.isFinal) {
                    NSLog(@"%@", result.bestTranscription.formattedString);
                    
                    [BFRecognitionRequest translatePhrase:result.bestTranscription.formattedString from:language to:speakLanguage handler:^(NSString *translated) {
                        [welf speak:translated in:speakLanguage];
                        [welf stopWaiting];
                        NSLog(@"%@: %@", language, translated);
                    }];
                }
            }];
            // should call startCapture method in main queue or it may crash
            dispatch_async(dispatch_get_main_queue(), ^{
                [self startCapture];
            });
        }
    }];
}

- (void)startCapture
{
    NSError *error;
    self.capture = [[AVCaptureSession alloc] init];
    [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    AVCaptureDevice *audioDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (audioDev == nil){
        NSLog(@"Couldn't create audio capture device");
        return ;
    }

    // create mic device
    AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDev error:&error];
    if (error != nil){
        NSLog(@"Couldn't create audio input");
        return ;
    }

    // add mic device in capture object
    if ([self.capture canAddInput:audioIn] == NO){
        NSLog(@"Couldn't add audio input");
        return ;
    }
    [self.capture addInput:audioIn];
    // export audio data
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if ([self.capture canAddOutput:audioOutput] == NO){
        NSLog(@"Couldn't add audio output");
        return ;
    }
    [self.capture addOutput:audioOutput];
    [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    [self.capture startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [self.speechRequest appendAudioSampleBuffer:sampleBuffer];
}

- (void)stopAudio {
    [self endCapture];
    [self endRecognizer];
}

- (void)endRecognizer
{
    [self endCapture];
    [self.speechRequest endAudio];
}

-(void)endCapture
{
    if (self.capture != nil && [self.capture isRunning]){
        [self.capture stopRunning];
    }
}

# pragma mark - Speech Synthesizer

- (AVSpeechSynthesizer *)speechSynt
{
    if(!_speechSynt) {
        _speechSynt = [AVSpeechSynthesizer new];
    }
    
    return _speechSynt;
}

- (void)speak:(NSString *)phrase in:(NSString *)language
{
    AVSpeechUtterance *sentence   = [[AVSpeechUtterance alloc] initWithString:phrase];
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:language];
    sentence.voice = voice;

    [self.speechSynt speakUtterance:sentence];
}

# pragma mark - visual coolness

- (void)roundSomeCorners
{
    self.activitySpinner.layer.cornerRadius = 8;
    self.otherTalkButton.layer.cornerRadius = 15;
    self.otherTalkButton.transform = CGAffineTransformMakeRotation(M_PI);    
    self.meTalkButton.layer.cornerRadius = 15;
    
    [self.activitySpinner startAnimating];
    [self.activitySpinner setHidden:YES];
    self.statusLabel.text = @"";
    self.recordingView.alpha = 0;
    self.recordingView.backgroundColor = [UIColor clearColor];
    
    
    self.waveform = [[SCSiriWaveformView alloc] initWithFrame:self.recordingView.bounds];
    self.waveform.alpha = 0.5;
    [self.waveform setBackgroundColor:[UIColor clearColor]];
    [self.waveform setWaveColor:[UIColor darkGrayColor]];
    [self.recordingView addSubview:self.waveform];
    
}

- (void)makeMeWait
{
    self.recordingView.alpha = 0;
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.activityView.transform = CGAffineTransformIdentity;
                         
                         self.statusLabel.alpha = 1;
                         self.statusLabel.text = @"Translating";
                     }];
    
    self.activitySpinner.hidden = NO;
    [self.waveTimer invalidate];
    self.waveTimer = nil;
}

- (void)makeThemWait
{
    self.recordingView.alpha = 0;
    [UIView animateWithDuration:0.5
                     animations:^{
                         CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI);
                         self.activityView.transform = transform;
                         
                         self.statusLabel.alpha = 1;
                         self.statusLabel.text = @"Translating";
                     }];
    
    self.activitySpinner.hidden = NO;
    [self.waveTimer invalidate];
}

- (void)stopWaiting
{
    self.recordingView.alpha = 0;
    self.activitySpinner.hidden = YES;
    
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.statusLabel.alpha = 0;
                     }];
}

- (void)tick:(NSTimer*)timer
{
    static CGFloat lastValue = 0.5;
    static CGFloat direction = -1;
    CGFloat randval = ((float)(rand()%2000))/8000.0;
    
    if(randval < 0.05)
    {
        direction *= -1;
//        NSLog(@"swithing randomly");
    }
    if(direction * randval + lastValue < 0 || direction * randval + lastValue > 1 )
    {
        direction *= -1;
//        NSLog(@"swithing at limit");
    }
    lastValue += direction * randval;
    
//    NSLog(@"dance %f",randval);
    [self.waveform updateWithLevel:lastValue];
}

- (void)showStartRecording
{
    [UIView animateWithDuration:0.4
                     animations:^{
                         self.recordingView.alpha = 1;
                     }];
    
    self.waveTimer = [NSTimer scheduledTimerWithTimeInterval:0.025 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
}

# pragma mark - Actions

- (IBAction)startRecording:(UIButton *)sender
{
    [self showStartRecording];
    
    [self recordAudio:[BFSettingsManager settings].yourLocale speakIn:[BFSettingsManager settings].myLocale];
}

- (IBAction)stopRecording:(UIButton *)sender
{
    [self stopAudio];

    [self makeThemWait];
}

- (IBAction)meStartRecording:(UIButton *)sender
{
    [self showStartRecording];
    [self recordAudio:[BFSettingsManager settings].myLocale speakIn:[BFSettingsManager settings].yourLocale];
}

- (IBAction)meStopRecording:(UIButton *)sender
{
    [self stopAudio];
    [self makeMeWait];
}

@end
