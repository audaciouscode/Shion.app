//
//  Event.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ASMutableDictionary.h"

@interface Event : ASMutableDictionary
{

}

+ (Event *) eventWithType:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			  description:(NSString *) description value:(id) value date:(NSDate *) date;

- (NSDate *) date;
- (NSString *) description;
- (NSString *) source;
- (NSString *) initiator;
- (NSString *) type;
- (id) value;

@end
