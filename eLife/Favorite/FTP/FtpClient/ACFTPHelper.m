//
//  FTPHelper.m
//  OnSong
//
//  Created by Jason Kichline on 3/24/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPHelper.h"

@implementation ACFTPHelper

+(NSURL*)urlByRemovingCredentials:(NSURL*)input {
	NSString* str = [input absoluteString];
	NSRange from = [str rangeOfString:@"://"];
	NSRange to = [str rangeOfString:@"@"];
	str = [NSString stringWithFormat:@"%@%@", [str substringToIndex:from.location + from.length], [str substringFromIndex:to.location + to.length]];
	return [NSURL URLWithString:str];
}

+(NSURL*)urlByAddingCredentials:(NSURL*)input username:(NSString*)username password:(NSString*)password {
	NSString* absString = [input absoluteString];
	
	// If we already have credentials, send it out
	if(username == nil || [absString rangeOfString:@"@"].length > 0) {
		return input;
	}
	
	// Insert the username/password
	NSMutableString* str = [NSMutableString stringWithString:absString];
	NSRange at = [str rangeOfString:@"://"];
	NSString* pwd = @"";
	if(password != nil) {
		pwd = [NSString stringWithFormat:@":%@", password];
	}
	[str insertString:[NSString stringWithFormat:@"%@%@@", username, pwd] atIndex:at.location + at.length];

    
    NSURL *url = [NSURL URLWithString:str];
	return url;
}

@end
