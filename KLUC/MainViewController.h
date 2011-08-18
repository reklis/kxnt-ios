//
//  MainViewController.h
//  KLUC
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import "FlipsideViewController.h"
#import "AQLevelMeter.h"
#import "AudioStreamer.h"
#import "TwitterFeed.h"

@interface MainViewController : UIViewController
<FlipsideViewControllerDelegate>
{
    AudioStreamer* streamer;
    UIButton *contactButton;
    UILabel *nowPlayingBanner;
    UIImageView *logoImage;
    NSTimer* scrollingTimer;
    TwitterFeed* twitter;
    UIActivityIndicatorView *loadingIndicator;
    UIImageView *textMask;
}

@property (nonatomic, retain) IBOutlet UIButton *contactButton;

@property (nonatomic, retain) IBOutlet UILabel *nowPlayingBanner;
@property (nonatomic, retain) IBOutlet UIButton* playPauseButton;
@property (nonatomic, retain) IBOutlet AQLevelMeter* lvlMeter;
@property (nonatomic, retain) IBOutlet UIImageView *logoImage;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, retain) IBOutlet UIImageView *textMask;

@property (nonatomic, retain) NSString* streamSource;
@property (nonatomic, retain) NSDictionary* radioConfig;
@property (nonatomic, retain) NSURL* tweetActionUrl;

- (IBAction)showInfo:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)showContactPage:(id)sender;

- (void) enterBackground;
- (void) enterForground;

- (BOOL) isPlaying;

@end
