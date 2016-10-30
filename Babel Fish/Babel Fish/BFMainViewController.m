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
#import "lame/lame.h"
#import "BFSettingsManager.h"
#import "BFRecognitionRequest.h"

@interface BFMainViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate, SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynt;
@property (strong, nonatomic) AVAudioEngine *audioEngine;
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
        switch(status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized: NSLog(@"Let do it"); break;
            case SFSpeechRecognizerAuthorizationStatusDenied: NSLog(@"Naah"); break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined: NSLog(@"???"); break;
            case SFSpeechRecognizerAuthorizationStatusRestricted: NSLog(@"Don't touch me"); break;
        }
    }];
//    NSURL *soundFileURL = [NSURL fileURLWithPath:[self soundFilePath]];
//    NSDictionary *recordSettings = @{
//        AVEncoderAudioQualityKey    : @(AVAudioQualityMin),
//        AVEncoderBitRateKey         : @16,
//        AVNumberOfChannelsKey       : @1,
//        AVSampleRateKey             : @(BFAudioSampleRate)
//    };
//
//    NSError *error;
//    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL
//                                                 settings:recordSettings
//                                                    error:&error];
//    if (error) {
//        NSLog(@"error: %@", error.localizedDescription);
//    }
}

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available
{
    NSLog(@"Available: %@", available ? @"YES" : @"NO");
}

# pragma mark - Audio Processing

- (void)recordAudio:(NSString *)language speakIn:(NSString *)speakLanguage {
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        if (status == SFSpeechRecognizerAuthorizationStatusAuthorized){
            NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:language];
            SFSpeechRecognizer *sf =[[SFSpeechRecognizer alloc] initWithLocale:local];
            self.speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
            [sf recognitionTaskWithRequest:self.speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
                       [BFRecognitionRequest translatePhrase:result.bestTranscription.formattedString from:language to:speakLanguage handler:^(NSString *translated) {
                           [self speak:translated in:language];
                       }];
                //NSLog(@"%@", result.bestTranscription);
            }];
            // should call startCapture method in main queue or it may crash
            dispatch_async(dispatch_get_main_queue(), ^{
                [self startCapture];
            });
        }
    }];

//    [self stopAudio];
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//    [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
//    [audioSession setActive:true error:nil];
//
//    self.recognitionRequest = [SFSpeechAudioBufferRecognitionRequest new];
//    self.recognitionRequest.shouldReportPartialResults = YES;
//
//    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:language];
//    SFSpeechRecognizer *recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
//
//    __block AVAudioInputNode *inputNode = self.audioEngine.inputNode;
//    __weak __typeof(self) welf = self;
//    self.recognitionTask = [recognizer recognitionTaskWithRequest:self.recognitionRequest
//                                                    resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
//
//                                                        if(result) {
//                                                            NSLog(@"Translate %@", result.bestTranscription);
//                                                        }
//
//                                                        if(!error) {
//                                                            [welf.audioEngine stop];
//                                                            welf.recognitionRequest = nil;
//                                                            welf.recognitionTask = nil;
//                                                            [inputNode removeTapOnBus:0];
//
//                                                        }
//    }];
//
//    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
//    [inputNode installTapOnBus:0 bufferSize:1024
//                        format:recordingFormat
//                         block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
//                             [welf.recognitionRequest appendAudioPCMBuffer:buffer];
//                         }];
//    [self.audioEngine prepare];
//    [self.audioEngine startAndReturnError:nil];
    
    //[_audioRecorder record];
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully
{

}

- (void)endRecognizer
{
    // END capture and END voice Reco
    // or Apple will terminate this task after 30000ms.
    [self endCapture];
    [self.speechRequest endAudio];
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

-(void)endCapture
{
    if (self.capture != nil && [self.capture isRunning]){
        [self.capture stopRunning];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [self.speechRequest appendAudioSampleBuffer:sampleBuffer];
}

//- (IBAction)playAudio:(id)sender {
//    [self stopAudio];
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
//    NSError *error;
//    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_audioRecorder.url
//                                                          error:&error];
//    _audioPlayer.delegate = self;
//    _audioPlayer.volume = 1.0;
//    if (error) {
//        NSLog(@"Error: %@", error.localizedDescription);
//    } else {
//        [_audioPlayer play];
//    }
//}

- (void)stopAudio {
    [self endCapture];
    [self endRecognizer];
    
    if (_audioRecorder.recording) {
        [_audioRecorder stop];
    } else if (_audioPlayer.playing) {
        [_audioPlayer stop];
    }
}

- (void)convertAudio
{
    NSString *filePath = [self soundFilePath];
    
    NSString *mp3FileName = @"Mp3File";
    mp3FileName = [mp3FileName stringByAppendingString:@".mp3"];
    NSString *mp3FilePath = [NSString stringWithFormat:@"%@/%@",[self soundFileDir],mp3FileName];
    
    NSLog(@"%@ to...\n%@/%@", filePath, mp3FilePath, mp3FileName);
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([filePath cStringUsingEncoding:1], "rb");  //source
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 44100);
        lame_set_VBR(lame, vbr_off);
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            NSLog(@"Read %d",read);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            NSLog(@"Writing %d to mp3 buffer.", write);
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"convert Finished: %@",mp3FilePath);
//        [self performSelectorOnMainThread:@selector(convertMp3Finish)
//                               withObject:nil
//                            waitUntilDone:YES];
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

-(void)setCurrentPhrase:(NSString *)currentPhrase
{
//    [BFRecognitionRequest detectLanguage:currentPhrase handler:^(NSString *detectedLanguage) {
//       [BFRecognitionRequest translatePhrase:currentPhrase from: to:detectedLanguage handler:^(NSString *) {
//           
//       }]
//    }];
    
//    NSMutableString *url = [NSMutableString string];
//    [url appendString:@"https://www.googleapis.com/language/translate/v2/detect"];
//    [url appendFormat:@"?key=%@", BFGoogleApiKey];
//    [url appendFormat:@"&q=%@", [currentPhrase stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
//
//    [BFNetworkRequest getWithURL:url handler:^(id detectJSON, NSError *error) {
//        if(detectJSON) {
//            NSArray *alternatives = detectJSON[@"data"][@"detections"];
//            NSString *source = [(NSDictionary *)alternatives[0][0] objectForKey:@"language"];
//            
//            NSMutableString *translate = [NSMutableString string];
//            [translate appendString:@"https://www.googleapis.com/language/translate/v2"];
//            [translate appendFormat:@"?key=%@", BFGoogleApiKey];
//            [translate appendFormat:@"&source=%@", source];
//            [translate appendFormat:@"&target=%@", @"en"];
//            [translate appendFormat:@"&q=%@", [currentPhrase stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
//            
//            [BFNetworkRequest getWithURL:translate handler:^(id translateJSON, NSError *error) {
//                if(translateJSON) {
//                    NSString *phrase = translateJSON[@"data"][@"translations"][0][@"translatedText"];
//                    [self speak:phrase];
//                } else {
//                    NSLog(@"ERROR ON TRANSLATE");
//                }
//            }];
//        
//        } else {
//            NSLog(@"ERROR ON DETECT");
//        }
//    }];
    
    //[self speak:currentPhrase];
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
    self.recordingView.backgroundColor = [UIColor greenColor];
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

- (void)showStartRecording
{
    [UIView animateWithDuration:0.4
                     animations:^{
                         self.recordingView.alpha = 1;
                     }];
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
    
    NSString *fromLanguage = [BFSettingsManager settings].yourLocale;
    NSString *toLanguage   = [BFSettingsManager settings].myLocale;
    [self processAudio:fromLanguage to:toLanguage];
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

    NSString *fromLanguage = [BFSettingsManager settings].myLocale;
    NSString *toLanguage   = [BFSettingsManager settings].yourLocale;
    [self processAudio:fromLanguage to:toLanguage];
    [self makeMeWait];
}

- (AVAudioEngine *)audioEngine
{
    if(!_audioEngine) {
        _audioEngine = [AVAudioEngine new];
    }

    return _audioEngine;
}

# pragma mark - Networking inside the view controller, like a boss

- (void)processAudio:(NSString *)fromLanguage to:(NSString *)toLanguage
{


    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:fromLanguage];
    SFSpeechRecognizer *recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    SFSpeechAudioBufferRecognitionRequest *request = [SFSpeechAudioBufferRecognitionRequest new];
    SFSpeechRecognitionTask *task = [SFSpeechRecognitionTask new];
    AVAudioEngine *audioEngine = [AVAudioEngine new];


//    //[self convertAudio];
//    NSString *service = @"https:/speech.googleapis.com/v1beta1/speech:syncrecognize";
//    service = [service stringByAppendingString:@"?key="];
//    service = [service stringByAppendingString:BFGoogleApiKey];
//
//    NSData *audioData       = [NSData dataWithContentsOfFile:[self soundFilePath]];
//
//    NSDictionary *configRequest = @{
//        @"encoding"         : @"LINEAR16",
//        @"sampleRate"       : @(BFAudioSampleRate),
//        @"languageCode"     : fromLanguage,
//        @"maxAlternatives"  : @30
//    };
//
//    NSDictionary *audioRequest = @{
//        @"content" : [audioData base64EncodedStringWithOptions:0]
//    };
//    NSDictionary *requestDictionary = @{
//        @"config"   : configRequest,
//        @"audio"    : audioRequest
//    };
//
//    NSError *error;
//    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary
//                                                          options:0
//                                                            error:&error];
//
//    [BFNetworkRequest postWithURL:service data:requestData handler:^(id response, NSError *error) {
//        if (!error && response) {
////            [self process:response];
//            if(response) {
//                NSArray *alternatives = response[@"results"][0][@"alternatives"];
//                NSString *target = [(NSDictionary *)alternatives.firstObject objectForKey:@"transcript"];
//                [BFRecognitionRequest translatePhrase:target from:fromLanguage to:toLanguage handler:^(NSString *translatedPhrase) {
//                    [self speak:translatedPhrase in:toLanguage];
//                }];
//            }
//        } else {
//            NSLog(@"ERROR: %@", error.localizedDescription);
//        }
//    }];
}

- (void)process:(NSDictionary *)json
{
    if(json) {
        NSArray *alternatives = json[@"results"][0][@"alternatives"];
        NSString *target = [(NSDictionary *)alternatives.firstObject objectForKey:@"transcript"];
        
        [self stopWaiting];
        self.currentPhrase = target;
    }
}

//
// Helpers
//

- (NSString*) soundFileDir {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    return docsDir;
}

- (NSString *) soundFilePath {
    NSString *docsDir = [self soundFileDir];
    
    return [docsDir stringByAppendingPathComponent:@"sound.caf"];
}

@end
