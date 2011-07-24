//
//  MainViewController.m
//  KXNT
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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

static NSString* streamSource = @"http://4583.live.streamtheworld.com:80/KXNTAMAAC_SC";
static NSString* streamEmailContact = @"steve@stevenohrdenlive.com";

@interface MainViewController(Private)

- (void)destroyStreamer;
- (void)createStreamer;
- (void)playbackStateChanged:(NSNotification *)aNotification;

@end


@implementation MainViewController

@synthesize lvlMeter;
@synthesize composeMessageButton;
@synthesize playPauseButton;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // hide the mail button on devices that don't have mail installed
    if (![MFMailComposeViewController canSendMail]) {
        [composeMessageButton setHidden:YES];
    }
    
    // setup the level meters
    UIColor *bgColor = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5];
    [lvlMeter setBackgroundColor:bgColor];
    [lvlMeter setBorderColor:bgColor];
    [bgColor release];
    [lvlMeter setVertical:YES];
    [lvlMeter setRefreshHz:1./60.];
    [lvlMeter setChannelNumbers:[NSArray arrayWithObjects:[NSNumber numberWithInt:0], nil]];
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
    [lvlMeter setAq: nil];
}

- (void) enterForground
{
    [lvlMeter setAq: [streamer audioQueue]];
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
	if ([streamer isWaiting])
	{
        [lvlMeter setAq: nil];
        
        [self.playPauseButton setImage:[UIImage imageNamed:@"loading.png"]
                              forState:UIControlStateNormal];
	}
	else if ([streamer isPlaying])
	{
        [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]
                              forState:UIControlStateNormal];
        
        [lvlMeter setAq: [streamer audioQueue]];
	}
	else if ([streamer isIdle])
	{
        [lvlMeter setAq: nil];
		[self destroyStreamer];
        
        [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"]
                              forState:UIControlStateNormal];
	}
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
    [super viewDidUnload];

    [self setComposeMessageButton:nil];
    [self setPlayPauseButton:nil];
    [self setLvlMeter:nil];
}

- (void)dealloc
{
    [composeMessageButton release];
    [playPauseButton release];
    [lvlMeter release];
    [super dealloc];
}

@end
