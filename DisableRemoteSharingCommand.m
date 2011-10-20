//
//  DisableRemoteSharingCommand.m
//  Shion
//
//  Created by Chris Karr on 8/2/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "DisableRemoteSharingCommand.h"

@implementation DisableRemoteSharingCommand

- (id) performDefaultImplementation
{
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKeyPath:@"share_remote"];

	return nil;
}

@end
