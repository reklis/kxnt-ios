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
- (void) nowPlayingBannerTapped:(id)sender;

- (void) showAlert:(NSString*)title message:(NSString*)message;
- (void) showLoading;
- (void) showPlaying;
- (void) showPaused;

@end


@implementation MainViewController

@synthesize loadingIndicator;
@synthesize textMask;
@synthesize lvlMeter;
@synthesize logoImage;
@synthesize contactButton;
@synthesize nowPlayingBanner;
@synthesize playPauseButton;
@synthesize streamSource;
@synthesize radioConfig;
@synthesize tweetActionUrl;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString* configPath = [[[NSBundle mainBundle] pathForResource:@"RadioConfig" ofType:@"plist"] stringByExpandingTildeInPath];
    self.radioConfig = [NSDictionary dictionaryWithContentsOfFile:configPath];
    NSLog(@"Radio Configuration: %@", radioConfig);
    
    scrollingTimer = nil;
    
    // setup the level meters
    UIColor* bgColor = [[[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5] autorelease];
    [lvlMeter setBackgroundColor:bgColor];
    [lvlMeter setBorderColor:[UIColor blackColor]];
    
    [lvlMeter setVertical:YES];
    [lvlMeter setRefreshHz:1./60.];
    [lvlMeter setChannelNumbers:[NSArray arrayWithObjects:[NSNumber numberWithInt:0], nil]];
    
    // wire up tap gesture for tweet url handling
    UITapGestureRecognizer* nowPlayingTap = [[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(nowPlayingBannerTapped:)] autorelease];
    [nowPlayingTap setNumberOfTapsRequired:1];
    [self.textMask setUserInteractionEnabled:YES];
    [self.textMask addGestureRecognizer:nowPlayingTap];
}

- (BOOL) isPlaying
{
    BOOL playing = ([self.playPauseButton.imageView.image isEqual:[UIImage imageNamed:@"play.png"]]);
    return playing;
}

- (void) showLoading
{
    [self.playPauseButton setImage:[UIImage imageNamed:@"loading.png"]
                          forState:UIControlStateNormal];
    [loadingIndicator startAnimating];
}

- (void) showPlaying
{
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]
                          forState:UIControlStateNormal];
    [loadingIndicator stopAnimating];
}

- (void) showPaused
{
    [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"]
                          forState:UIControlStateNormal];
    [loadingIndicator stopAnimating];
}

- (IBAction)playPause:(id)sender
{
    if ([loadingIndicator isAnimating]) return;
    
    if ([self isPlaying])
	{
        [self showLoading];
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
                         if ((nil == errorOrNil) && (tweetText)) {
                             NSString* streamDescription = [self.radioConfig objectForKey:kDescriptionKey];
                             NSString* s = [streamDescription stringByAppendingFormat:@" @%@: %@", streamTwitterAccount, tweetText];
                             UIFont* f = self.nowPlayingBanner.font;
                             CGSize size = [s sizeWithFont:f];
                             CGRect newBounds = CGRectMake(0, 0, size.width, size.height);
                             self.nowPlayingBanner.bounds = newBounds;
                             self.nowPlayingBanner.text = s;
                             self.tweetActionUrl = [TwitterFeed extractUrlFromTweet:tweetText];
                         } else {
                             NSLog(@"%@", errorOrNil);
                             NSString* s = [self.radioConfig objectForKey:kDescriptionKey];
                             UIFont* f = self.nowPlayingBanner.font;
                             CGSize size = [s sizeWithFont:f];
                             CGRect newBounds = CGRectMake(0, 0, size.width, size.height);
                             self.nowPlayingBanner.bounds = newBounds;
                             self.nowPlayingBanner.text = s;
                         }
                         
                         dispatch_async(dispatch_get_main_queue(), ^(void) {
                             [self performSelector:@selector(fetchLatestTweet)
                                        withObject:nil
                                        afterDelay:600.];
                         });
                     }];
}

- (void)nowPlayingBannerTapped:(id)sender
{
    if ((self.tweetActionUrl)
        &&
        (self.nowPlayingBanner.alpha == 1.0)
        &&
        ([self.nowPlayingBanner isHidden] == NO)
    ) {
        if ([[UIApplication sharedApplication] canOpenURL:self.tweetActionUrl]) {
            [[UIApplication sharedApplication] openURL:self.tweetActionUrl];
        }
    }
}

- (void)showContactPage:(id)sender
{
    NSURL* contactUrl = [NSURL URLWithString:[self.radioConfig objectForKey:kHomepageKey]];
    UIApplication* a = [UIApplication sharedApplication];
    if ([a canOpenURL:contactUrl]) {
        [a openURL:contactUrl];
    }
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
    
    [lvlMeter setAq: nil];
    [self destroyStreamer];
    
    [UIView animateWithDuration:1
                     animations:^(void) {
                         [lvlMeter setAlpha:0.];
                     }];
    
    [self showPaused];
}

- (void)handlePlayingState
{
    [self showPlaying];
    
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
    [self showLoading];
}

- (void)scrollNowPlayingBanner:(NSTimer*)timer
{
    CGAffineTransform t = CGAffineTransformTranslate(self.nowPlayingBanner.transform, -1., 0.);
    CGRect bannerRect = self.nowPlayingBanner.bounds;
    CGFloat bannerWidth = CGRectGetWidth(bannerRect);
    if (t.tx <= bannerWidth*-.9) {
        t = CGAffineTransformTranslate(t, bannerWidth*1.8, 0);
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

- (NSString *)emailToAddress {
    return [self.radioConfig objectForKey:kContactKey];
}

- (NSString *)emailSubject {
    return [self.radioConfig objectForKey:kEmailSubjectKey];
}

- (NSString *)showcaseDescription {
    return [self.radioConfig objectForKey:kHeadlinerSchedule];
}

- (NSString *)showcaseTagline {
    return [self.radioConfig objectForKey:kHeadlinerTagline];
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
    [scrollingTimer invalidate];
    [scrollingTimer release];
    scrollingTimer = nil;
    [self setNowPlayingBanner:nil];
    [self setPlayPauseButton:nil];
    [self setLvlMeter:nil];
    [self setLogoImage:nil];
    [self setStreamSource:nil];
    [self setRadioConfig:nil];
    [self setTweetActionUrl:nil];
    [self setLoadingIndicator:nil];
    [self setTextMask:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    [scrollingTimer invalidate];
    [scrollingTimer release];
    [playPauseButton release];
    [lvlMeter release];
    [nowPlayingBanner release];
    [logoImage release];
    [twitter release];
    [streamSource release];
    [radioConfig release];
    [loadingIndicator release];
    [tweetActionUrl release];
    [textMask release];
    [super dealloc];
}

@end
