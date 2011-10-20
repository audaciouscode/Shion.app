//
//  XMPPSoftwareVersionCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "XMPPSoftwareVersionCommand.h"

#include <sys/utsname.h>

@implementation XMPPSoftwareVersionCommand

- (NSXMLElement *) responseElement
{
	NSXMLElement * query = [NSXMLElement elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"jabber:iq:version"]];
	
	NSXMLElement * name = [NSXMLElement elementWithName:@"name"];
	[name setStringValue:@"Shion"];
	[query addChild:name];
	
	 NSXMLElement * version = [NSXMLElement elementWithName:@"version"];
	[version setStringValue:[NSString stringWithFormat:@"%@ (Mac OS X)", [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"]]];
	[query addChild:version];

/*	NSMutableString * osString = [NSMutableString stringWithString:@"Mac OS X "];
	
	[osString appendString:[[NSProcessInfo processInfo] operatingSystemVersionString]];
	
	struct utsname  uts;
	
	uname(&uts);
	
	[osString appendString:@" ("];
	[osString appendString:[NSString stringWithCString:uts.machine]];
	[osString appendString:@")"];
	
	NSXMLElement * os = [NSXMLElement elementWithName:@"version"];
	[os setStringValue:osString];
	[query addChild:os]; */
	
	return query;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
