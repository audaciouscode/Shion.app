//
//  EnableRemoteSharingCommand.m
//  Shion
//
//  Created by Chris Karr on 8/2/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "EnableRemoteSharingCommand.h"


@implementation EnableRemoteSharingCommand

- (id) performDefaultImplementation
{
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKeyPath:@"share_remote"];

	return nil;
}

@end
