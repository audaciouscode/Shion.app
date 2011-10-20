//
//  XMPPIQNode.h
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPManager.h"

@interface XMPPIQCommand : NSObject 
{
	NSString * fromString;
	NSString * toString;
	NSString * typeString;
	NSString * identifierString;
	
	NSString * queryString;
	
	XMPPManager * manager;
}

+ (XMPPIQCommand *) commandForElement:(NSXMLElement *) iqElement sender:(XMPPManager *) sender;

- (id) initWithFrom:(NSString *) from to:(NSString *) to type:(NSString *) type id:(NSString *) identifier query:(NSString *) query;
- (void) setTo:(NSString *) to;
- (NSXMLElement *) execute;

- (NSXMLElement *) responseElement;
- (NSXMLElement *) errorElement;

@end
