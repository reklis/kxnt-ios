//
//  TwitterFeed.m
//  KXNT
//
//  Created by Steven Fusco on 8/8/11.
//  Copyright 2011 Cibo Technology, LLC. All rights reserved.
//

#import "TwitterFeed.h"

#define kUserTimelineApiFormat @"http://api.twitter.com/1/statuses/user_timeline.json?include_entities=0&trim_user=1&include_rts=0&exclude_replies=1&contributor_details=0&screen_name=%@&count=1"

NSString* kTwitterFeedResultErrorDomain = @"SBJsonStreamParserError";
NSString* kTwitterFeedResultErrorUserInfoKey = @"SBJsonStreamParserError";

@interface TwitterFeed(Private)

- (void) cleanup;
- (void) parseTweet:(NSDictionary*)result;

@end


@implementation TwitterFeed

- (void)dealloc {
    if (conn) {
        [self cancel];
        [self cleanup];
    }
    if (resultCallback) {
        [resultCallback release];
    }
    [super dealloc];
}

- (void) fetchLatestTweet:(NSString*)screen_name callback:(TwitterFeedResultCallback)cb
{
    if (conn) {
        [self cancel];
        [self cleanup];
    }
    
	parser = [[SBJsonStreamParser alloc] init];
    parser.delegate = self;

    NSString* apiUrlString = [NSString stringWithFormat:kUserTimelineApiFormat, screen_name];
    NSURL* apiUrl = [NSURL URLWithString:apiUrlString];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:apiUrl
                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:60.0];
    
	conn = [[NSURLConnection alloc] initWithRequest:req
                                           delegate:self];
    
    if (resultCallback) {
        [resultCallback release];
    }
    resultCallback = [cb copy];
}

+ (NSURL*) extractUrlFromTweet:(NSString*)t
{
    @try {
        NSScanner* httpUrlScanner = [NSScanner scannerWithString:t];
        [httpUrlScanner scanUpToString:@"http" intoString:NULL];
        NSString* httpUrl = nil;
        [httpUrlScanner scanUpToString:@" " intoString:&httpUrl];
        
        if (httpUrl) {
            
            return [NSURL URLWithString:httpUrl];
        
        } else {
            
            NSMutableString *tel = [NSMutableString stringWithCapacity:t.length];
            NSScanner *telScanner = [NSScanner scannerWithString:t];
            NSCharacterSet *numbers = [NSCharacterSet 
                                       characterSetWithCharactersInString:@"0123456789"];
            
            while ([telScanner isAtEnd] == NO) {
                NSString *buffer;
                if ([telScanner scanCharactersFromSet:numbers intoString:&buffer]) {
                    [tel appendString:buffer];
                } else {
                    [telScanner setScanLocation:([telScanner scanLocation] + 1)];
                }
            }
            
            if ([tel length] >= 7) {
                [tel insertString:@"tel://" atIndex:0];
                return [NSURL URLWithString:tel];
            }
            
        }
    }
    @catch (NSException *exception) {
        NSLog(@"error extracting url: %@", exception);
    }
    
    return nil;
}

- (void) cancel
{
    [conn cancel];
}

- (void) cleanup
{
    [conn release]; conn = nil;
    [parser release]; parser = nil;
}

#pragma mark SBJsonStreamParserDelegate

- (void) parseTweet:(NSDictionary*)result
{
    if ([[result allKeys] containsObject:@"text"]) {
        @try {
            if (resultCallback) {
                NSString* tweetText = [result objectForKey:@"text"];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    resultCallback(nil, tweetText);
                });
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
}

- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array
{
    //    NSLog(@"%@", array);
    [self parseTweet:[array lastObject]];
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict
{
    //    NSLog(@"%@", dict);
    [self parseTweet:dict];
}

#pragma mark NSURLConnectionDelegate

//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//	NSLog(@"Connection didReceiveResponse: %@ - %@", response, [response MIMEType]);
//}

//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//	NSLog(@"Connection didReceiveAuthenticationChallenge: %@", challenge);
//    
//	NSURLCredential *credential = [NSURLCredential credentialWithUser:username.text
//															 password:password.text
//														  persistence:NSURLCredentialPersistenceForSession];
//    
//	[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
//}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	//NSLog(@"Connection didReceiveData of length: %u", data.length);
    
	// Parse the new chunk of data. The parser will append it to
	// its internal buffer, then parse from where it left off in
	// the last chunk.
	SBJsonStreamParserStatus status = [parser parse:data];
    
	if (status == SBJsonStreamParserError) {
		NSLog(@"Parser error: %@", parser.error);
        if (resultCallback) {
            NSDictionary* userInfo = [NSDictionary dictionaryWithObject:parser.error
                                                                 forKey:kTwitterFeedResultErrorUserInfoKey];
            NSError* err = [NSError errorWithDomain:kTwitterFeedResultErrorDomain
                                               code:1
                                           userInfo:userInfo];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                resultCallback(err, nil);
            });
        }
	} else if (status == SBJsonStreamParserWaitingForData) {
		//NSLog(@"Parser waiting for more data");
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    @try {
        NSLog(@"Connection failed! Error - %@ %@",
              [error localizedDescription],
              [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
        
        if (resultCallback) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                resultCallback(error, nil);
            });
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    @finally {
        [self cleanup];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self cleanup];
}

@end
