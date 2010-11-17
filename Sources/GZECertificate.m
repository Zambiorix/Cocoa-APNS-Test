//	--------------------------------------------------------------------------------------------------------------------
//
//  GZECertificate.m
//  APNSTest
//
//  Created by Gerd Van Zegbroeck on 16/11/10.
//
//  Managing Software : http://www.managingsoftware.com
//
//	--------------------------------------------------------------------------------------------------------------------
//
//	This file is part of APNSTest - Apple Push Notification Test.
//
//	APNSTest is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	APNSTest is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with APNSTest. If not, see <http://www.gnu.org/licenses/>.
//
//	--------------------------------------------------------------------------------------------------------------------

#import "GZECertificate.h"


//	--------------------------------------------------------------------------------------------------------------------
//	class GZECertificate
//	--------------------------------------------------------------------------------------------------------------------

@implementation GZECertificate

//	--------------------------------------------------------------------------------------------------------------------
//	property synthesizers
//	--------------------------------------------------------------------------------------------------------------------

@synthesize key;

@synthesize name;

@synthesize identity;

//	--------------------------------------------------------------------------------------------------------------------
//	method certificateWithName
//	--------------------------------------------------------------------------------------------------------------------

+ (id)certificateWithKey:(NSString *)aKey withName:(NSString *)aName withIdentity:(SecIdentityRef)aIdentity
{
	return [[[self alloc] initCertificateWithKey:aKey withName:aName withIdentity:aIdentity] autorelease];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method initCertificateWithName
//	--------------------------------------------------------------------------------------------------------------------

- (id)initCertificateWithKey:(NSString *)aKey withName:(NSString *)aName withIdentity:(SecIdentityRef)aIdentity
{
	if (self = [super init])
	{
		key = [aKey copy];
		
		name = [aName copy];
		
		identity = aIdentity;
		
		CFRetain(identity);
	}
	
	return self;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method dealloc
//	--------------------------------------------------------------------------------------------------------------------

- (void)dealloc
{
	[key release]; key = nil;
	
	[name release]; name = nil;
	
	CFRelease(identity); identity = nil;
	
	[super dealloc];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method description
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)description
{
	return name;
}

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------