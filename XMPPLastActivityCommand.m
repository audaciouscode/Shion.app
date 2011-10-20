//
//  XMPPLastActivityCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "XMPPLastActivityCommand.h"

@implementation XMPPLastActivityCommand

- (NSXMLElement *) responseElement
{
	NSNumber * idle = nil;
	
	NSXMLElement * query = [NSXMLElement elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"jabber:iq:last"]];

	[query setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", [idle intValue]] forKey:@"seconds"]];
	
	return query;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
