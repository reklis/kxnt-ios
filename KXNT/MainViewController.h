//
//  MainViewController.h
//  KXNT
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "FlipsideViewController.h"
#import "AQLevelMeter.h"
#import "AudioStreamer.h"
#import "TwitterFeed.h"

@interface MainViewController : UIViewController
<FlipsideViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
    AudioStreamer* streamer;
    UIButton *composeMessageButton;
    UILabel *nowPlayingBanner;
    UIImageView *loadingFlare;
    UIImageView *logoImage;
    NSTimer* loadingTimer;
    NSTimer* scrollingTimer;
    TwitterFeed* twitter;
}

@property (nonatomic, retain) IBOutlet UIButton *composeMessageButton;

@property (nonatomic, retain) IBOutlet UILabel *nowPlayingBanner;
@property (nonatomic, retain) IBOutlet UIButton* playPauseButton;
@property (nonatomic, retain) IBOutlet AQLevelMeter* lvlMeter;
@property (nonatomic, retain) IBOutlet UIImageView *loadingFlare;
@property (nonatomic, retain) IBOutlet UIImageView *logoImage;

- (IBAction)showInfo:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)composeMessage:(id)sender;
//- (IBAction)showSite:(id)sender;

- (void) enterBackground;
- (void) enterForground;

@end
