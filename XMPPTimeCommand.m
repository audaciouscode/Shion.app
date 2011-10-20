//
//  XMPPTimeCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "XMPPTimeCommand.h"

@implementation XMPPTimeCommand

- (NSXMLElement *) responseElement
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	NSDate * now = [NSDate date];
	
	NSXMLElement * time = [NSXMLElement elementWithName:@"time"];
	[time addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:xmpp:time"]];
	
	[dateFormatter setDateFormat:@"ZZZ"];	
	
	NSXMLElement * tzo = [NSXMLElement elementWithName:@"tzo"];
	[tzo setStringValue:[dateFormatter stringFromDate:now]];
	[time addChild:tzo];

	NSMutableString * dateString = [NSMutableString string];

	NSXMLElement * utc = [NSXMLElement elementWithName:@"utc"];

	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	[dateString appendString:[dateFormatter stringFromDate:now]];
	[dateString appendString:@"T"];

	[dateFormatter setDateFormat:@"HH:mm:ss"];
	[dateString appendString:[dateFormatter stringFromDate:now]];
	[dateString appendString:@"Z"];

	[utc setStringValue:dateString];
	[dateFormatter release];
	
	[time addChild:utc];
	
	return time;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
