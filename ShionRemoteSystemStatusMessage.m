//
//  ShionRemoteSystemStatusMessage.m
//  Shion
//
//  Created by Chris Karr on 10/14/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "ShionRemoteSystemStatusMessage.h"
#import "AppDelegate.h"

@implementation ShionRemoteSystemStatusMessage

- (NSXMLElement *) responseElement
{
	// AppDelegate * delegate = [NSApp delegate];

	NSXMLElement * statusMessage = [NSXMLElement elementWithName:@"status"];
	[statusMessage addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:remote-control"]];
	
	NSNumber * status = nil; // [delegate systemPropertyForName:@"network status"];

	NSXMLElement * item = [NSXMLElement elementWithName:@"network"];
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@%%", status, nil], @"status", nil]];
	[statusMessage addChild:item];
	
	item = [NSXMLElement elementWithName:@"local-time"];
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[[NSDate date] description], @"date", nil]];
	[statusMessage addChild:item];
	
	NSValue * location = nil; // [delegate systemPropertyForName:@"location"];

	item = [NSXMLElement elementWithName:@"item"];
	
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", [location pointValue].y, nil], @"latitude",
									 [NSString stringWithFormat:@"%f", [location pointValue].x, nil], @"longitude", nil]];
	[statusMessage addChild:item];
	
	return statusMessage;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
