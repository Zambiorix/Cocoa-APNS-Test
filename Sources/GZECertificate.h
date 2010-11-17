//	--------------------------------------------------------------------------------------------------------------------
//
//  GZECertificate.h
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

#import <Foundation/Foundation.h>

//	--------------------------------------------------------------------------------------------------------------------
//	class GZECertificate
//	--------------------------------------------------------------------------------------------------------------------

@interface GZECertificate : NSObject 
{
	
@private
	
	NSString *key;
	
	NSString *name;

	SecIdentityRef identity;
}

//	--------------------------------------------------------------------------------------------------------------------
//	properties
//	--------------------------------------------------------------------------------------------------------------------

@property (readonly) NSString *key;

@property (readonly) NSString *name;

@property (readonly) SecIdentityRef identity;

//	--------------------------------------------------------------------------------------------------------------------
//	method prototypes
//	--------------------------------------------------------------------------------------------------------------------

+ (id)certificateWithKey:(NSString *)aKey withName:(NSString *)aName withIdentity:(SecIdentityRef)aIdentity;

- (id)initCertificateWithKey:(NSString *)aKey withName:(NSString *)aName withIdentity:(SecIdentityRef)aIdentity;

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------