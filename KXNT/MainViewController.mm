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
 // http://provisioning.streamtheworld.com/pls/KMXBFM.pls
*/

#define kHomepageKey @"homepage"
#define kContactKey @"contact"
#define kSourceKey @"source"
#define kDescriptionKey @"description"
#define kTwitterKey @"twitteraccount"

@interface MainViewController(Private)

- (void) beginStreaming;
- (void) discoverStreamSource;
- (void) createStreamer;
- (void) destroyStreamer;

- (void) playbackStateChanged:(NSNotification *)aNotification;
- (void) handleWaitingState;
- (void) handlePlayingState;
- (void) handleIdleState;

- (void) rotateLoadingFlare:(NSTimer*)timer;
- (void) scrollNowPlayingBanner:(NSTimer*)timer;
- (void) fetchLatestTweet;
- (void) showAlert:(NSString*)title message:(NSString*)message;

@end


@implementation MainViewController

@synthesize lvlMeter;
@synthesize loadingFlare;
@synthesize logoImage;
@synthesize composeMessageButton;
@synthesize nowPlayingBanner;
@synthesize playPauseButton;
@synthesize streamSource;
@synthesize radioConfig;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString* configPath = [[[NSBundle mainBundle] pathForResource:@"RadioConfig" ofType:@"plist"] stringByExpandingTildeInPath];
    self.radioConfig = [NSDictionary dictionaryWithContentsOfFile:configPath];
    NSLog(@"Radio Configuration: %@", radioConfig);
    
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
}

- (IBAction)playPause:(id)sender
{
    if ([self.playPauseButton.imageView.image isEqual:[UIImage imageNamed:@"play.png"]])
	{		
        [self.playPauseButton setImage:[UIImage imageNamed:@"loading.png"]
                              forState:UIControlStateNormal];
        
        [self beginStreaming];
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

- (void)fetchLatestTweet
{
    NSString* streamTwitterAccount = [self.radioConfig objectForKey:kTwitterKey];
    if (!twitter) {
        twitter = [[TwitterFeed alloc] init];
    }
    [twitter fetchLatestTweet:streamTwitterAccount
                     callback:^(NSError *errorOrNil, NSString *tweetText) {
                         if (nil == errorOrNil) {
                             NSString* streamDescription = [self.radioConfig objectForKey:kDescriptionKey];
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

- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                           otherButtonTitles: nil]
                            autorelease];
    
    [alert performSelector:@selector(show)
                  onThread:[NSThread mainThread]
                withObject:nil
             waitUntilDone:NO];
}

#pragma mark Background Audio Controls

- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear: animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [self fetchLatestTweet];
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
    NSString* streamEmailContact = [self.radioConfig objectForKey:kContactKey];
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

- (void)beginStreaming
{
    if (self.streamSource) {
        [self createStreamer];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [streamer start];
        });
    } else {
        [self discoverStreamSource];
    }
}

- (void) discoverStreamSource
{
    dispatch_queue_t q = dispatch_queue_create("com.cibotechnology.beginstreaming", nil);
    dispatch_async(q, ^(void) {
        NSString* streamPlaylist = [self.radioConfig objectForKey:kSourceKey];
        NSURL* plsUrl = [NSURL URLWithString:streamPlaylist];
        
        NSError* err = nil;
        NSString* pls = [NSString stringWithContentsOfURL:plsUrl
                                                 encoding:NSUTF8StringEncoding
                                                    error:&err];
        if (err) {
            NSLog(@"Error loading %@: %@", plsUrl, err);
            
            NSString* title = NSLocalizedStringFromTable(@"LoadError", @"Errors", @"Load failure alert title");
            NSString* message = NSLocalizedStringFromTable(@"PlaylistFailedToLoad", @"Errors", @"Failed to load .pls file from provisioning portal message");
            [self showAlert:title message:message];
            [self handleIdleState];
        } else {
            @try {
                NSScanner* scanner = [NSScanner scannerWithString:pls];
                NSMutableDictionary* sources = [NSMutableDictionary dictionary];
                NSString* cr = @"\r\n";
                NSString* kvpSeparator = @"=";
                NSString* playlistHeader = @"[playlist]\r\n";
                [scanner scanString:playlistHeader intoString:NULL];
                while (![scanner isAtEnd]) {
                    NSString* k;
                    [scanner scanUpToString:kvpSeparator intoString:&k];
                    [scanner scanString:kvpSeparator intoString:NULL];
                    NSString* v;
                    [scanner scanUpToString:cr intoString:&v];
                    [scanner scanString:cr intoString:NULL];
                    
                    if (v && k) {
                        [sources setObject:v forKey:k];
                    }
                }
                
                NSLog(@"%@ => %@", plsUrl, sources);
                
                if ([[sources allKeys] containsObject:@"File1"]) {
                    self.streamSource = [sources objectForKey:@"File1"];
                    [self createStreamer];
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [streamer start];
                    });
                } else {
                    NSString* title = NSLocalizedStringFromTable(@"ScannerError", @"Errors", @"Scanner failure alert title");
                    NSString* message = NSLocalizedStringFromTable(@"ScannerErrorMessage", @"Errors", @"Failed to scan .pls file from provisioning portal");
                    [self showAlert:title message:message];
                    [self handleIdleState];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"Exception while parsing PLS: %@", exception);
                NSString* title = NSLocalizedStringFromTable(@"ScannerError", @"Errors", @"Scanner failure alert title");
                NSString* message = NSLocalizedStringFromTable(@"ScannerErrorMessage", @"Errors", @"Failed to scan .pls file from provisioning portal");
                [self showAlert:title message:message];
                [self handleIdleState];
            }
        }
    });
}

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
    [self setStreamSource:nil];
    [self setRadioConfig:nil];
        
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
    [streamSource release];
    [radioConfig release];
    [super dealloc];
}

@end
