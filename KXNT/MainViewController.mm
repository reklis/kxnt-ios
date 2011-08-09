//
//  MainViewController.m
//  KXNT
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import "MainViewController.h"

/*
 
 // http://provisioning.streamtheworld.com/pls/KXNTAM.pls
 
 [playlist]
 File1=http://4553.live.streamtheworld.com:80/KXNTAM_SC
 File2=http://4553.live.streamtheworld.com:3690/KXNTAM_SC
 File3=http://4553.live.streamtheworld.com:443/KXNTAM_SC
 File4=http://4723.live.streamtheworld.com:80/KXNTAM_SC
 File5=http://4723.live.streamtheworld.com:3690/KXNTAM_SC
 File6=http://4723.live.streamtheworld.com:443/KXNTAM_SC
 File7=http://4693.live.streamtheworld.com:80/KXNTAM_SC
 File8=http://4693.live.streamtheworld.com:3690/KXNTAM_SC
 File9=http://4693.live.streamtheworld.com:443/KXNTAM_SC
 File10=http://1331.live.streamtheworld.com:80/KXNTAM_SC
 File11=http://1331.live.streamtheworld.com:3690/KXNTAM_SC
 File12=http://1331.live.streamtheworld.com:443/KXNTAM_SC
 File13=http://4983.live.streamtheworld.com:80/KXNTAM_SC
 File14=http://4983.live.streamtheworld.com:3690/KXNTAM_SC
 File15=http://4983.live.streamtheworld.com:443/KXNTAM_SC
 File16=http://4583.live.streamtheworld.com:80/KXNTAM_SC
 File17=http://4583.live.streamtheworld.com:3690/KXNTAM_SC
 File18=http://4583.live.streamtheworld.com:443/KXNTAM_SC
 Title1=KXNTAM_SC
 Title2=KXNTAM_SC-Bak
 Length1=-1
 NumberOfEntries=18
 Version=2
 */

/*
 // http://provisioning.streamtheworld.com/pls/KMXBFM.pls
 
 File1=http://2453.live.streamtheworld.com:80/KMXBFM_SC
 File2=http://2453.live.streamtheworld.com:3690/KMXBFM_SC
 File3=http://2453.live.streamtheworld.com:443/KMXBFM_SC
*/

//static NSString* streamHome = @"http://www.kxnt.com";
static NSString* streamSource = @"http://4583.live.streamtheworld.com:80/KXNTAMAAC_SC";
//static NSString* streamSource = @"http://2453.live.streamtheworld.com:443/KMXBFM_SC";
static NSString* streamEmailContact = @"steve@stevenohrdenlive.com";
static NSString* streamDescription = @"Now Playing: CBS News Radio KXNT 100.5 FM Covering Las Vegas Metropolitan Area ";
static NSString* streamTwitterAccount = @"kxntnewsradio";

@interface MainViewController(Private)

- (void)destroyStreamer;
- (void)createStreamer;
- (void)playbackStateChanged:(NSNotification *)aNotification;
- (void)handleWaitingState;
- (void)handlePlayingState;
- (void)handleIdleState;
- (void)rotateLoadingFlare:(NSTimer*)timer;
- (void)scrollNowPlayingBanner:(NSTimer*)timer;
@end


@implementation MainViewController

@synthesize lvlMeter;
@synthesize loadingFlare;
@synthesize logoImage;
@synthesize composeMessageButton;
@synthesize nowPlayingBanner;
@synthesize playPauseButton;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scrollingTimer = nil;
    
    // hide the loading flare until the user taps play
    [loadingFlare setAlpha:0];
    loadingTimer = nil;
    
    // hide the mail button on devices that don't have mail installed
    if (![MFMailComposeViewController canSendMail]) {
        [composeMessageButton setHidden:YES];
    }
    
    // setup the level meters
    UIColor* bgColor = [[[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5] autorelease];
    [lvlMeter setBackgroundColor:bgColor];
    [lvlMeter setBorderColor:[UIColor blackColor]];
    
    [lvlMeter setVertical:YES];
    [lvlMeter setRefreshHz:1./60.];
    [lvlMeter setChannelNumbers:[NSArray arrayWithObjects:[NSNumber numberWithInt:0], nil]];
    
//    UITapGestureRecognizer* singleTapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSite:)] autorelease];
//    [logoImage addGestureRecognizer:singleTapGesture];
}

- (IBAction)playPause:(id)sender
{
    if ([self.playPauseButton.imageView.image isEqual:[UIImage imageNamed:@"play.png"]])
	{		
		[self createStreamer];
        [self.playPauseButton setImage:[UIImage imageNamed:@"loading.png"]
                              forState:UIControlStateNormal];
		[streamer start];
	}
	else
	{
		[streamer stop];
	}
}

- (void) enterBackground
{
    [lvlMeter setHidden:YES];
}

- (void) enterForground
{
    if ([streamer isPlaying]) {
        [lvlMeter setHidden:NO];
    }
}

//- (void)showSite:(id)sender
//{
//    NSURL* streamHomeUrl = [NSURL URLWithString:streamHome];
//    if ([[UIApplication sharedApplication] canOpenURL:streamHomeUrl]) {
//        [[UIApplication sharedApplication] openURL:streamHomeUrl];
//    }
//}

#pragma mark Background Audio Controls

- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear: animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    if (!twitter) {
        twitter = [[TwitterFeed alloc] init];
    }
    [twitter fetchLatestTweet:streamTwitterAccount
                     callback:^(NSError *errorOrNil, NSString *tweetText) {
                         if (nil == errorOrNil) {
                             NSString* s = [streamDescription stringByAppendingString:tweetText];
                             UIFont* f = self.nowPlayingBanner.font;
                             CGSize size = [s sizeWithFont:f];
                             CGRect newBounds = CGRectMake(0, 0, size.width, size.height);
                             self.nowPlayingBanner.bounds = newBounds;
                             self.nowPlayingBanner.text = s;
                         } else {
                             NSLog(@"%@", errorOrNil);
                         }
                     }];
}

- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    switch(event.subtype) {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self playPause:nil];
            break;
        default:
            break;
    }
}

- (void) viewWillDisppear: (BOOL) animated
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    [super viewWillDisappear: animated];
}

#pragma mark MFMailComposeViewControllerDelegate


- (IBAction)composeMessage:(id)sender
{
    MFMailComposeViewController* mailComposer = [[[MFMailComposeViewController alloc] init] autorelease];
    [mailComposer setToRecipients:[NSArray arrayWithObject:streamEmailContact]];
    [mailComposer setSubject:@"Steve Nohrden Live!"];
    [mailComposer setMailComposeDelegate:self];
    [self presentModalViewController:mailComposer animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark AudioStreamer Notifications

- (void)destroyStreamer
{
	if (streamer)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ASStatusChangedNotification
                                                      object:streamer];
		
		[streamer stop];
		[streamer release];
		streamer = nil;
	}
}

- (void)createStreamer
{
	if (streamer)
	{
		return;
	}
    
	[self destroyStreamer];
	
	NSString *escapedValue = [streamSource stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *url = [NSURL URLWithString:escapedValue];
	streamer = [[AudioStreamer alloc] initWithURL:url];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:streamer];
}

- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([streamer isWaiting]) {
        [self handleWaitingState];
    } else if ([streamer isPlaying]) {
        [self handlePlayingState];
	} else if ([streamer isIdle]) {
        [self handleIdleState];
	}
}

- (void)handleIdleState
{
    [nowPlayingBanner setAlpha:1.];
    [UIView animateWithDuration:.25
                     animations:^(void) {
                         [nowPlayingBanner setAlpha:0.];
                     }
                     completion:^(BOOL finished) {
                         //[nowPlayingBanner setHidden:YES];
                     }];
    
    [UIView animateWithDuration:.3
                     animations:^(void) {
                         [self.loadingFlare setAlpha:0.];
                     }
                     completion:^(BOOL finished) {
                         [loadingTimer invalidate];
                         [loadingTimer release];
                         loadingTimer = nil;
                     }];
    
    [lvlMeter setAq: nil];
    [self destroyStreamer];
    
    [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"]
                          forState:UIControlStateNormal];
    
    [UIView animateWithDuration:1
                     animations:^(void) {
                         [lvlMeter setAlpha:0.];
                     }];
}

- (void)handlePlayingState
{
    [UIView animateWithDuration:.3
                     animations:^(void) {
                         [self.loadingFlare setAlpha:0.];
                     }
                     completion:^(BOOL finished) {
                         [loadingTimer invalidate];
                         [loadingTimer release];
                         loadingTimer = nil;
                     }];
    
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]
                          forState:UIControlStateNormal];
    
    [nowPlayingBanner setAlpha:0.];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [nowPlayingBanner setHidden:NO];
        [lvlMeter setHidden:NO];
        
        [UIView animateWithDuration:.25
                         animations:^(void) {
                             [nowPlayingBanner setAlpha:1.];
                         }];
        [UIView animateWithDuration:1
                         animations:^(void) {
                             [lvlMeter setAlpha:1.];
                         }];
        
        [lvlMeter setAq: [streamer audioQueue]];
        
        if (!scrollingTimer) {
            scrollingTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                                      interval:1./60.
                                                        target:self
                                                      selector:@selector(scrollNowPlayingBanner:)
                                                      userInfo:nil
                                                       repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:scrollingTimer
                                      forMode:NSDefaultRunLoopMode];
        }
    });
}

- (void)handleWaitingState
{
    [lvlMeter setAq: nil];
    
    [self.playPauseButton setImage:[UIImage imageNamed:@"loading.png"]
                          forState:UIControlStateNormal];
    
    if (!loadingTimer) {
        loadingTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                                interval:1./60.
                                                  target:self
                                                selector:@selector(rotateLoadingFlare:)
                                                userInfo:nil
                                                 repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:loadingTimer
                                  forMode:NSDefaultRunLoopMode];
    }
    
    [UIView animateWithDuration:.3
                     animations:^(void) {
                         [self.loadingFlare setAlpha:1.];
                     }];
}

- (void)rotateLoadingFlare:(NSTimer *)timer
{
    self.loadingFlare.transform = CGAffineTransformRotate(self.loadingFlare.transform, .1);
}

- (void)scrollNowPlayingBanner:(NSTimer*)timer
{
    CGRect windowRect = self.view.window.bounds;
    CGFloat windowWidth = CGRectGetWidth(windowRect);
    CGAffineTransform t = CGAffineTransformTranslate(self.nowPlayingBanner.transform, -.5, 0.);
    CGRect bannerRect = self.nowPlayingBanner.bounds;
    CGFloat bannerWidth = CGRectGetWidth(bannerRect);
    if (t.tx <= (bannerWidth*-.5)-(windowWidth*1.25)) {
        t = CGAffineTransformTranslate(t, bannerWidth+windowWidth*1.25, 0);
    }
    self.nowPlayingBanner.transform = t;
}

#pragma mark FlipsideViewControllerDelegate

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{    
    FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    controller.delegate = self;
    
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
    
    [controller release];
}

#pragma mark UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
    [self setLoadingFlare:nil];
    [self setNowPlayingBanner:nil];
    [self setComposeMessageButton:nil];
    [self setPlayPauseButton:nil];
    [self setLvlMeter:nil];
    [self setLogoImage:nil];
        
    [scrollingTimer invalidate];
    [scrollingTimer release];
    scrollingTimer = nil;
    
    [loadingTimer invalidate];
    [loadingTimer release];
    loadingTimer = nil;
    
    [super viewDidUnload];
}

- (void)dealloc
{
    [scrollingTimer invalidate];
    [scrollingTimer release];
    [loadingTimer invalidate];
    [loadingTimer release];
    [composeMessageButton release];
    [playPauseButton release];
    [lvlMeter release];
    [loadingFlare release];
    [nowPlayingBanner release];
    [logoImage release];
    [twitter release];
    [super dealloc];
}

@end
