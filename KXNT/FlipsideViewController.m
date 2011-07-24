//
//  FlipsideViewController.m
//  KXNT
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"


@implementation FlipsideViewController

@synthesize delegate=_delegate;

- (void)dealloc
{
    [zoomableImages release];
    [image8 release];
    [image7 release];
    [image6 release];
    [image5 release];
    [image4 release];
    [image3 release];
    [image2 release];
    [image1 release];
    [doneButton release];
    [imageZoomGesture release];
    [navigationBar release];
    [showcaseImage release];
    [showcaseDescription release];
    [showcaseTagline release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    imageOriginBounds = CGRectZero;
    imageOriginCenter = CGPointZero;
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
    
    imageZoomGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(zoomImage:)];
    [imageZoomGesture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:imageZoomGesture];
    
    zoomableImages = [[NSArray alloc] initWithObjects:image1, image2, image3, image4, image5, image6, image7, image8, nil];
}

- (void)viewDidUnload
{
    [doneButton release];
    doneButton = nil;
    
    [image8 release];
    image8 = nil;
    [image7 release];
    image7 = nil;
    [image6 release];
    image6 = nil;
    [image5 release];
    image5 = nil;
    [image4 release];
    image4 = nil;
    [image3 release];
    image3 = nil;
    [image2 release];
    image2 = nil;
    [image1 release];
    image1 = nil;
    
    [zoomableImages release];
    zoomableImages = nil;
    
    [self.view removeGestureRecognizer:imageZoomGesture];
    [imageZoomGesture release];
    imageZoomGesture = nil;

    [navigationBar release];
    navigationBar = nil;
    
    [showcaseImage release];
    showcaseImage = nil;
    [showcaseDescription release];
    showcaseDescription = nil;
    [showcaseTagline release];
    showcaseTagline = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (void)zoomImage:(UIGestureRecognizer*)zoomGesture
{
    // done button takes priority
    CGPoint p = [zoomGesture locationOfTouch:0 inView:self.view];
    if (CGRectContainsPoint(navigationBar.frame, p)) {
        [self done:doneButton];
        return;
    }

    // bail if we are already zoomed on something
    if (!CGPointEqualToPoint(imageOriginCenter, CGPointZero)) return;
    
    // find the correct image to zoom
    UIImageView* iv = nil;
    for (UIImageView* zoomableImage in zoomableImages) {
        CGPoint p = [zoomGesture locationOfTouch:0 inView:zoomableImage];
        CGRect imageFrame = [zoomableImage frame];
        CGFloat w = CGRectGetWidth(imageFrame);
        CGFloat h = CGRectGetHeight(imageFrame);
        CGRect touchableRect = CGRectMake(0, 0, w, h);
        if (CGRectContainsPoint(touchableRect, p)) {
            iv = zoomableImage;
            break;
        }
    }
    
    if (iv == nil) return;
    
    CGRect viewFrame = self.view.frame;
    CGFloat h = CGRectGetHeight(viewFrame);
    CGFloat w = CGRectGetWidth(viewFrame);
    CGPoint c = CGPointMake(w/2., h*.6);
    
    imageOriginBounds = iv.bounds;
    imageOriginCenter = iv.center;
    
    [UIView animateWithDuration:.3
                     animations:^(void) {
                         [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                                                forView:iv
                                                  cache:YES];
                         
                         CGRect r = CGRectMake(0, 0, 180, 58);
                         [iv setBounds:r];
                         [iv setCenter:c];
                     }
                     completion:^(BOOL finished) {
                         UITapGestureRecognizer* dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                          action:@selector(dismissImage:)];
                         [dismissGesture setNumberOfTapsRequired:1];
                         [iv addGestureRecognizer:dismissGesture];
                         [dismissGesture release];
                     }];
}

- (void)dismissImage:(UIGestureRecognizer*)dismissGesture
{
    UIImageView* iv = (UIImageView*) [dismissGesture view];
    NSAssert(iv != nil, @"invalid gesture target");
    
    [iv removeGestureRecognizer:dismissGesture];
    
    [UIView animateWithDuration:.3
                     animations:^(void) {
                         [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                                                forView:iv
                                                  cache:YES];
                         
                         [iv setBounds:imageOriginBounds];
                         [iv setCenter:imageOriginCenter];
                     }
                     completion:^(BOOL finished) {
                         imageOriginBounds = CGRectZero;
                         imageOriginCenter = CGPointZero;
                     }];
}

@end
