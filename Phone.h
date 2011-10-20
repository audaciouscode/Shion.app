//
//  Phone.h
//  Shion
//
//  Created by Chris Karr on 4/26/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

#import "Device.h"

@interface Phone : Device 
{

}

+ (Phone *) phone;

+ (NSString *) normalizePhoneNumber:(NSString *) number;
+ (ABPerson *) findPersonByNumber:(NSString *) number;

- (void) addCall:(NSDictionary *) call;

@end
