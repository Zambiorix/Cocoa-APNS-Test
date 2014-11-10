//
//  GZEFormatCategory.m
//  APNSTest
//
//  Created by Julian Weinert on 10.11.14.
//
//  Julian Weinert : https://github.com/julian-weinert
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

#import "GZEFormatCategory.h"

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatCategory
//	--------------------------------------------------------------------------------------------------------------------

@implementation GZEFormatCategory

//	--------------------------------------------------------------------------------------------------------------------
//	property synthesizers
//	--------------------------------------------------------------------------------------------------------------------

@synthesize delegate;

//	--------------------------------------------------------------------------------------------------------------------
//	method stringForObjectValue
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)stringForObjectValue:(id)aObject 
{ 
	return [aObject description];
} 

//	--------------------------------------------------------------------------------------------------------------------
//	method getObjectValue forString errorDescription
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)getObjectValue:(id *)aObject 

			 forString:(NSString *)aString 

	  errorDescription:(NSString **)aError 
{ 	
	*aObject = aString;
	
	if (aError)
	{
		*aError = nil;
	}
	
	return YES;	
} 

//	--------------------------------------------------------------------------------------------------------------------
//	method isPartialStringValid newEditingString errorDescription
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)isPartialStringValid:(NSString *)aPartialString 

			newEditingString:(NSString **)aNewString 

			errorDescription:(NSString **)aError
{	
	NSLog(@"Category : changed");
	
	if (aError)
	{
		*aError = nil;
	}
	
	if (delegate)
	{
		return [delegate formatCategoryCheck:self forString:aPartialString];
	}
	
	return YES; 
}

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------