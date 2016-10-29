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
#import "lame/lame.h"
#import "BFSettingsManager.h"

@interface BFMainViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynt;
@property (copy  , nonatomic) NSString *currentPhrase;
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
    NSURL *soundFileURL = [NSURL fileURLWithPath:[self soundFilePath]];
    NSDictionary *recordSettings = @{
        AVEncoderAudioQualityKey    : @(AVAudioQualityMin),
        AVEncoderBitRateKey         : @16,
        AVNumberOfChannelsKey       : @1,
        AVSampleRateKey             : @(BFAudioSampleRate)
    };

    NSError *error;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL
                                                 settings:recordSettings
                                                    error:&error];
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
    }
}

# pragma mark - Audio Processing

- (void)recordAudio {
    [self stopAudio];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [_audioRecorder record];
}

- (IBAction)playAudio:(id)sender {
    [self stopAudio];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_audioRecorder.url
                                                          error:&error];
    _audioPlayer.delegate = self;
    _audioPlayer.volume = 1.0;
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
    } else {
        [_audioPlayer play];
    }
}

- (void)stopAudio {
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

- (void)speak:(NSString *)phrase
{
    AVSpeechUtterance *sentence = [[AVSpeechUtterance alloc] initWithString:phrase];
    [self.speechSynt speakUtterance:sentence];
}

-(void)setCurrentPhrase:(NSString *)currentPhrase
{
    NSMutableString *url = [NSMutableString string];
    [url appendString:@"https://www.googleapis.com/language/translate/v2/detect"];
    [url appendFormat:@"?key=%@", BFGoogleApiKey];
    [url appendFormat:@"&q=%@", [currentPhrase stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

    [BFNetworkRequest getWithURL:url handler:^(id detectJSON, NSError *error) {
        if(detectJSON) {
            NSArray *alternatives = detectJSON[@"data"][@"detections"];
            NSString *source = [(NSDictionary *)alternatives[0][0] objectForKey:@"language"];
            
            NSMutableString *translate = [NSMutableString string];
            [translate appendString:@"https://www.googleapis.com/language/translate/v2"];
            [translate appendFormat:@"?key=%@", BFGoogleApiKey];
            [translate appendFormat:@"&source=%@", source];
            [translate appendFormat:@"&target=%@", @"en"];
            [translate appendFormat:@"&q=%@", [currentPhrase stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            
            [BFNetworkRequest getWithURL:translate handler:^(id translateJSON, NSError *error) {
                if(translateJSON) {
                    NSString *phrase = translateJSON[@"data"][@"translations"][0][@"translatedText"];
                    [self speak:phrase];
                } else {
                    NSLog(@"ERROR ON TRANSLATE");
                }
            }];
        
        } else {
            NSLog(@"ERROR ON DETECT");
        }
    }];
    
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
    [self recordAudio];
}

- (IBAction)stopRecording:(UIButton *)sender
{
    [self stopAudio];
    [self processAudio];
    
    [self makeThemWait];
}

- (IBAction)meStartRecording:(UIButton *)sender
{
    [self showStartRecording];
    [self recordAudio];
}

- (IBAction)meStopRecording:(UIButton *)sender
{
    [self stopAudio];
    [self processAudio];
    
    [self makeMeWait];
}


# pragma mark - Networking inside the view controller, like a boss

- (void)processAudio
{
    //[self convertAudio];

    NSString *service = @"https:/speech.googleapis.com/v1beta1/speech:syncrecognize";
    service = [service stringByAppendingString:@"?key="];
    service = [service stringByAppendingString:BFGoogleApiKey];
    
    NSLocale *currentLocale = [BFSettingsManager settings].language;
    NSString *languageCode  = [currentLocale displayNameForKey:NSLocaleCountryCode value:currentLocale] ?: @"pt-BR";
    NSData *audioData       = [NSData dataWithContentsOfFile:[self soundFilePath]];
    
    NSDictionary *configRequest = @{
        @"encoding"         : @"LINEAR16",
        @"sampleRate"       : @(BFAudioSampleRate),
        @"languageCode"     : languageCode,
        @"maxAlternatives"  : @30
    };
    
    NSDictionary *audioRequest = @{
        @"content" : [audioData base64EncodedStringWithOptions:0]
    };
    NSDictionary *requestDictionary = @{
        @"config":configRequest,
        @"audio":audioRequest
    };
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                          options:0
                                                            error:&error];

    [BFNetworkRequest postWithURL:service data:requestData handler:^(id response, NSError *error) {
        if (!error) {
            [self process:response];
        }
    }];

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
