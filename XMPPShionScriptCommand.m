//
//  XMPPShionScriptCommand.m
//  Shion
//
//  Created by Chris Karr on 4/20/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "XMPPShionScriptCommand.h"

#import "LuaManager.h"

@implementation XMPPShionScriptCommand

- (NSXMLElement *) responseElement
{
	NSXMLElement * query = [NSXMLElement elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:script"]];
	
	[query addAttribute:[NSXMLNode attributeWithName:@"result" stringValue:@"submitted"]];

	if (script != nil)
	{
		[query setStringValue:script];
		
		[[LuaManager sharedInstance] runScript:script];
	}
	
	return query;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

- (void) setScript:(NSString *) queryScript
{
	if (script != nil)
		[script release];
	
	script = [queryScript retain];
}

- (void) dealloc
{
	if (script != nil)
		[script release];

	[super dealloc];
}

@end
