//
//  MainViewController_iPad.h
//  KLUC
//
//  Created by Steven Fusco on 8/13/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainViewController.h"

@interface MainViewController_iPad : MainViewController
<UIPopoverControllerDelegate>
{
    UIPopoverController* popover;
    UIImageView *background;
    UIImageView *backgroundSlab;
    UIImageView *logoFrame;
    UIImageView *textSlab;
    UIImageView *levelMeterMask;
    UIButton *scheduleButton;
    UIInterfaceOrientation currentOrientation;
}

@property (nonatomic, retain) IBOutlet UIImageView *background;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundSlab;
@property (nonatomic, retain) IBOutlet UIImageView *logoFrame;
@property (nonatomic, retain) IBOutlet UIImageView *textSlab;
@property (nonatomic, retain) IBOutlet UIImageView *levelMeterMask;
@property (nonatomic, retain) IBOutlet UIButton *scheduleButton;

@end
