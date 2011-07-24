//
//  MainViewController.h
//  KXNT
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "AQLevelMeter.h"
#import "AudioStreamer.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate>
{
    AudioStreamer* streamer;
}

@property (nonatomic, retain) IBOutlet UIButton* playPauseButton;
@property (nonatomic, retain) IBOutlet AQLevelMeter* lvlMeter;

- (IBAction)showInfo:(id)sender;
- (IBAction)playPause:(id)sender;

- (void) enterBackground;
- (void) enterForground;

@end
