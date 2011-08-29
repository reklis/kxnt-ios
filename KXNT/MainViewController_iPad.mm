//
//  MainViewController_iPad.m
//  KXNT
//
//  Created by Steven Fusco on 8/13/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import "MainViewController_iPad.h"

@interface MainViewController_iPad(Private)

- (void)presentPopoverFromSender:(id)sender withController:(UIViewController*)controller;
- (void) dismissPopover;

@end

@implementation MainViewController_iPad
@synthesize background;
@synthesize backgroundSlab;
@synthesize logoFrame;
@synthesize textSlab;
@synthesize levelMeterMask;
@synthesize scheduleButton;

- (IBAction)showInfo:(id)sender
{
    FlipsideViewController* flipside = [[[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil] autorelease];
    flipside.delegate = self;
    [self presentPopoverFromSender:sender withController:flipside];
}

- (void)presentPopoverFromSender:(id)sender withController:(UIViewController*)controller
{
    [self dismissPopover];
    
    popover = [[UIPopoverController alloc] initWithContentViewController:controller];
    [popover setPopoverContentSize:CGSizeMake(320., 480.)];
    [popover setDelegate:self];
    [popover presentPopoverFromRect:[sender frame]
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionAny
                           animated:YES];
}

- (void) dismissPopover
{
    if (popover) {
        [popover dismissPopoverAnimated:YES];
        [popover release];
        popover = nil;
    }
}

- (BOOL) isPlaying
{
    BOOL playing = ([self.playPauseButton.imageView.image isEqual:[UIImage imageNamed:@"play~ipad.png"]]);
    return playing;
}

- (void) showLoading
{
    [self.playPauseButton setImage:[UIImage imageNamed:@"loading~ipad.png"]
                          forState:UIControlStateNormal];
    [loadingIndicator startAnimating];
}

- (void) showPlaying
{
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause~ipad.png"]
                          forState:UIControlStateNormal];
    [loadingIndicator stopAnimating];
}

- (void) showPaused
{
    [self.playPauseButton setImage:[UIImage imageNamed:@"play~ipad.png"]
                          forState:UIControlStateNormal];
    [loadingIndicator stopAnimating];
}

#pragma mark FlipsideViewControllerDelegate

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissPopover];
}

#pragma UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self dismissPopover];
}

#pragma MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (error) {
        NSLog(@"Error composing message: %@", error);
    }
    
    [self dismissPopover];
}

#pragma Rotation

- (void) scrollNowPlayingBanner:(NSTimer*)timer
{
    CGRect bannerRect = self.nowPlayingBanner.bounds;
    CGFloat bannerWidth = CGRectGetWidth(bannerRect);
    CGAffineTransform t = CGAffineTransformTranslate(self.nowPlayingBanner.transform, -1., 0.);
    if (UIInterfaceOrientationIsPortrait(currentOrientation)) {
        if (t.tx <= bannerWidth*-.7) {
            t = CGAffineTransformTranslate(t, bannerWidth*1.4, 0);
        }
    } else {
        if (t.tx <= bannerWidth*-.66) {
            t = CGAffineTransformTranslate(t, bannerWidth*1.32, 0);
        }
    }
    self.nowPlayingBanner.transform = t;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [self.background setImage:[UIImage imageNamed:@"bk-Landscape~ipad.png"]];
        [self.backgroundSlab setImage:[UIImage imageNamed:@"Slab-Landscape~ipad.png"]];
        [self.textMask setImage:[UIImage imageNamed:@"txtMask-Landscape~ipad.png"]];
        
        [UIView animateWithDuration:duration
                         animations:^(void) {
            self.backgroundSlab.frame = CGRectMake(0, 0, 1024, 748);
            self.logoImage.center = CGPointMake(256, 274);
            self.logoImage.bounds = CGRectMake(0, 0, 483, 292);
            self.logoFrame.center = CGPointMake(256, 276);
            self.logoFrame.bounds = CGRectMake(0, 0, 493, 307);
            self.textSlab.center = CGPointMake(752, 520);
            self.textSlab.bounds = CGRectMake(0, 0, 507, 53);
            self.textMask.center = CGPointMake(512, 521);
            self.textMask.bounds = CGRectMake(0, 0, 1024, 46);
            self.lvlMeter.center = CGPointMake(751, 284);
            self.lvlMeter.bounds = CGRectMake(0, 0, 448, 313);
            self.levelMeterMask.center = CGPointMake(751, 284);
            self.levelMeterMask.bounds = CGRectMake(0, 0, 448, 313);
            self.playPauseButton.center = CGPointMake(756, 290);
            self.playPauseButton.bounds = CGRectMake(0,0, 298, 298);
            self.loadingIndicator.center = CGPointMake(756, 290);
            self.scheduleButton.center = CGPointMake(250, 483);
            self.scheduleButton.bounds = CGRectMake(0, 0, 481, 70);
            self.contactButton.center = CGPointMake(250, 563);
            self.contactButton.bounds = CGRectMake(0, 0, 481, 70);
            self.nowPlayingBanner.center = CGPointMake(751, 520);
                         }];
    } else {
        [self.background setImage:[UIImage imageNamed:@"bk~ipad.png"]];
        [self.backgroundSlab setImage:[UIImage imageNamed:@"Slab~ipad.png"]];
        [self.textMask setImage:[UIImage imageNamed:@"txtMask-Portrait~ipad.png"]];
        [UIView animateWithDuration:duration
                         animations:^(void) {
            self.backgroundSlab.frame = CGRectMake(-8, 0, 768, 1004);
            self.logoImage.center = CGPointMake(384, 178);
            self.logoImage.bounds = CGRectMake(0, 0, 495, 301);
            self.logoFrame.center = CGPointMake(386, 180);
            self.logoFrame.bounds = CGRectMake(0, 0, 508, 314);
            self.textSlab.center = CGPointMake(380, 378);
            self.textSlab.bounds = CGRectMake(0, 0, 507, 53);
            self.textMask.center = CGPointMake(384, 374);
            self.textMask.bounds = CGRectMake(0, 0, 768, 46);
            self.lvlMeter.center = CGPointMake(383, 576);
            self.lvlMeter.bounds = CGRectMake(0, 0, 448, 313);
            self.levelMeterMask.center = CGPointMake(383, 576);
            self.levelMeterMask.bounds = CGRectMake(0, 0, 448, 313);
            self.playPauseButton.center = CGPointMake(383, 577);
            self.playPauseButton.bounds = CGRectMake(0,0, 298, 298);
            self.loadingIndicator.center = CGPointMake(382, 576);
            self.scheduleButton.center = CGPointMake(383, 828);
            self.scheduleButton.bounds = CGRectMake(0, 0, 502, 76);
            self.contactButton.center = CGPointMake(383, 912);
            self.contactButton.bounds = CGRectMake(0, 0, 502, 76);
            self.nowPlayingBanner.center = CGPointMake(386, 378);
                         }];
    }
    
    currentOrientation = toInterfaceOrientation;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.nowPlayingBanner.transform = CGAffineTransformIdentity;
}

- (void) dealloc {
    [background release];
    [backgroundSlab release];
    [logoFrame release];
    [textSlab release];
    [levelMeterMask release];
    [scheduleButton release];
    [super dealloc];
}
- (void) viewDidUnload {
    [self setBackground:nil];
    [self setBackgroundSlab:nil];
    [self setLogoFrame:nil];
    [self setTextSlab:nil];
    [self setLevelMeterMask:nil];
    [self setScheduleButton:nil];
    [super viewDidUnload];
}
@end
