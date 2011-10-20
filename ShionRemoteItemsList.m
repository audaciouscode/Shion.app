//
//  ShionRemoteItemsList.m
//  Shion
//
//  Created by Chris Karr on 10/14/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "ShionRemoteItemsList.h"


@implementation ShionRemoteItemsList

- (NSXMLElement *) responseElement
{
	NSXMLElement * query = [NSXMLElement elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#items"]];
	[query setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"remote-control" forKey:@"node"]];
	
	NSXMLElement * item = [NSXMLElement elementWithName:@"item"];
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:toString, @"jid", 
									@"System Status & Information", @"name", @"status", @"node", nil]];
	[query addChild:item];

	item = [NSXMLElement elementWithName:@"item"];
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:toString, @"jid", 
									 @"Snapshot List", @"name", @"snapshots", @"node", nil]];
	[query addChild:item];

	item = [NSXMLElement elementWithName:@"item"];
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:toString, @"jid", 
									 @"Device List", @"name", @"devices", @"node", nil]];
	[query addChild:item];
		
	return query;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	
@end
