//
//  Command.h
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define CMD_RESULT_DESC @"description"
#define CMD_RESULT_VALUE @"value"
#define CMD_SUCCESS @"success"

@interface Command : NSObject 
{

}

- (NSDictionary *) execute;

@end
