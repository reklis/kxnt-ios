//
//  MIX94AppDelegate.h
//  MIX94
//
//  Created by Steven Fusco on 7/23/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface MIX94AppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;

@end
