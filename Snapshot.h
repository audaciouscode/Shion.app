//
//  Snapshot.h
//  Shion
//
//  Created by Chris Karr on 4/6/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ASMutableDictionary.h"

@interface Snapshot : ASMutableDictionary
{

}

+ (Snapshot *) snapshot;
+ (Snapshot *) snapshotFromData:(NSData *) data;

- (NSData *) data;

- (NSString *) identifier;

- (NSString *) name;
- (void) setName:(NSString *) name;

- (NSString *) category;
- (void) setCategory:(NSString *) category;

- (void) execute;

- (NSArray *) snapshotDevices;
- (void) removeDevices:(NSArray *) identifiers;

@end
