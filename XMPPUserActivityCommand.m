//
//  XMPPUserActivityCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "XMPPUserActivityCommand.h"

@implementation XMPPUserActivityCommand

- (void) setActivity:(NSString *) activity
{
	if (activityString != nil)
		[activityString release];
	
	activityString = [activity retain];
}

- (void) dealloc
{
	[activityString release];

	[super dealloc];
}

- (NSXMLElement *) responseElement
{
	NSXMLElement * pubsub = [NSXMLElement elementWithName:@"pubsub"];
	[pubsub addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/pubsub"]];
	
	NSXMLElement * publish = [NSXMLElement elementWithName:@"publish"];
	[publish setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"http://jabber.org/protocol/activity" forKey:@"node"]];
	
	NSXMLElement * item = [NSXMLElement elementWithName:@"item"];
	NSXMLElement * activity = [NSXMLElement elementWithName:@"activity"];

	[activity addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/activity"]];

	NSXMLElement * other = [NSXMLElement elementWithName:@"other"];
	[activity addChild:other];
	
	NSXMLElement * text = [NSXMLElement elementWithName:@"text"];
	[text setStringValue:activityString];
	[activity addChild:text];
	
	[item addChild:activity];
	[publish addChild:item];
	[pubsub addChild:publish];
	 
	return pubsub;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	


@end
