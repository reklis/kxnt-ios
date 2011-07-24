//
//  MainViewController.m
//  KXNT
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"

static NSString* streamSource = @"http://4723.live.streamtheworld.com:80/KXNTAM_SC";


@interface MainViewController(Private)

- (void)destroyStreamer;
- (void)createStreamer;
- (void)playbackStateChanged:(NSNotification *)aNotification;

@end


@implementation MainViewController

@synthesize lvlMeter;
@synthesize playPauseButton;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [super dealloc];
}

@end
