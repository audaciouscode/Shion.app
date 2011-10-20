//
//  XMPPServiceDiscoveryCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "XMPPServiceDiscoveryCommand.h"
#import <SystemConfiguration/SystemConfiguration.h>

@implementation XMPPServiceDiscoveryCommand

- (NSXMLElement *) responseElement
{
	NSXMLElement * query = [NSXMLElement elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#info"]];

	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults valueForKey:@"remote_label"] == nil)
		[defaults setValue:[(NSString *) SCDynamicStoreCopyComputerName(NULL, NULL) autorelease] forKeyPath:@"remote_label"];

	NSString * name = [defaults valueForKey:@"remote_label"];
	
	NSXMLElement * identity = [NSXMLElement elementWithName:@"identity"];
	[identity setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"bot", @"type", @"client", @"category", name, @"name", nil]];
	[query addChild:identity];
	
	NSArray * features = [NSArray arrayWithObjects:@"http://jabber.org/protocol/disco#info", @"http://jabber.org/protocol/disco#items", 
						  @"jabber:iq:time", @"jabber:iq:version", @"http://jabber.org/protocol/activity", 
						  @"jabber:client", @"urn:xmpp:avatar:data", @"urn:xmpp:avatar:metadata", @"urn:xmpp:time", @"vcard-temp", 
						  @"http://jabber.org/protocol/commands", @"jabber:x:data", @"shion:remote-control", nil];

	NSEnumerator * featureIter = [features objectEnumerator];
	NSString * var = nil;
	while (var = [featureIter nextObject])
	{
		NSXMLElement * feature = [NSXMLElement elementWithName:@"feature"];
		[feature setAttributesAsDictionary:[NSDictionary dictionaryWithObject:var forKey:@"var"]];
		
		[query addChild:feature];
	}
	
	return query;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
