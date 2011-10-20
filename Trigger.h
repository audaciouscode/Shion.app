//
//  Trigger.h
//  Shion
//
//  Created by Chris Karr on 5/4/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ASMutableDictionary.h"

#define TRIGGER_NAME @"trigger_name"

@interface Trigger : ASMutableDictionary 
{

}

+ (Trigger *) triggerForType:(NSString *) type;
+ (Trigger *) triggerFromData:(NSData *) data;

- (void) setType:(NSString *) type;
- (NSString *) type;

- (NSString *) name;
- (NSString *) action;
- (NSString *) identifier;
- (NSString *) actionDescription;
- (NSDate *) fired;

- (NSData *) data;


- (NSString *) description;

- (void) fire;

@end
