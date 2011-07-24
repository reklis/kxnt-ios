//
//  FlipsideViewController.h
//  KXNT
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlipsideViewControllerDelegate;

@interface FlipsideViewController : UIViewController
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
    CGRect imageOriginBounds;
    CGPoint imageOriginCenter;
    
    NSArray* zoomableImages;
    UITapGestureRecognizer* imageZoomGesture;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

- (void)zoomImage:(UIGestureRecognizer*)zoomGesture;
- (void)dismissImage:(UIGestureRecognizer*)dismissGesture;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end
