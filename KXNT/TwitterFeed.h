//
//  TwitterFeed.h
//  KXNT
//
//  Created by Steven Fusco on 8/8/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBJson.h"

extern NSString* kTwitterFeedResultErrorDomain;
extern NSString* kTwitterFeedResultErrorUserInfoKey;

typedef void (^TwitterFeedResultCallback)(NSError* errorOrNil, NSString* tweetText);

@interface TwitterFeed : NSObject
<SBJsonStreamParserDelegate>
{
    @private
    SBJsonStreamParser* parser;
    NSURLConnection* conn;
    TwitterFeedResultCallback resultCallback;
}

- (void) fetchLatestTweet:(NSString*)screen_name callback:(TwitterFeedResultCallback)cb;
- (void) cancel;
+ (NSURL*) extractUrlFromTweet:(NSString*)t;

@end
