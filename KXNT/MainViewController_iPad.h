//
//  MainViewController_iPad.h
//  KXNT
//
//  Created by Steven Fusco on 8/13/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainViewController.h"

@interface MainViewController_iPad : MainViewController
<UIPopoverControllerDelegate, MFMailComposeViewControllerDelegate>
{
    UIPopoverController* popover;
}

@end
