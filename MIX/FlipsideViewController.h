//
//  FlipsideViewController.h
//  MIX94
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@protocol FlipsideViewControllerDelegate;

@interface FlipsideViewController : UIViewController
<MFMailComposeViewControllerDelegate>
{
    IBOutlet UIImageView* image1;
    IBOutlet UIImageView* image2;
    IBOutlet UIImageView* image3;
    IBOutlet UIImageView* image4;
    IBOutlet UIImageView* image5;
    IBOutlet UIImageView* image6;
    IBOutlet UIImageView* image7;
    IBOutlet UIImageView* image8;
    IBOutlet UIBarButtonItem *doneButton;
    IBOutlet UINavigationBar *navigationBar;
    
    IBOutlet UIImageView *showcaseImage;
    IBOutlet UILabel *showcaseDescription;
    IBOutlet UILabel *showcaseTagline;
    
    @private
    UIImageView* currentlyZoomedImage;
    CGRect imageOriginBounds;
    CGPoint imageOriginCenter;
    
    NSArray* zoomableImages;
    UITapGestureRecognizer* imageZoomGesture;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

- (void)zoomImage:(UIGestureRecognizer*)zoomGesture;
- (void)dismissImage;

- (MFMailComposeViewController*) createMailComposer;

@end


@protocol FlipsideViewControllerDelegate
- (NSString*) emailToAddress;
- (NSString*) emailSubject;
- (NSString*) showcaseDescription;
- (NSString*) showcaseTagline;

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;

- (void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated;
- (void)dismissModalViewControllerAnimated:(BOOL)animated;
@end
