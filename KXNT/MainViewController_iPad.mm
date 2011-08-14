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

- (IBAction)composeMessage:(id)sender
{
    MFMailComposeViewController* mailComposer = [self createMailComposer];
    [self presentPopoverFromSender:sender withController:mailComposer];    
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

@end
