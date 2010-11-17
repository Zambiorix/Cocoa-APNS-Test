//	--------------------------------------------------------------------------------------------------------------------
//
//  GZEFormatAlert.m
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

#import "GZEFormatAlert.h"


//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatAlert
//	--------------------------------------------------------------------------------------------------------------------

@implementation GZEFormatAlert

//	--------------------------------------------------------------------------------------------------------------------
//	property synthesizers
//	--------------------------------------------------------------------------------------------------------------------

//	--------------------------------------------------------------------------------------------------------------------
//	method init
//	--------------------------------------------------------------------------------------------------------------------

- (id)init
{
	if (self = [super init])
	{
		//
	}
	
	return self;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method dealloc
//	--------------------------------------------------------------------------------------------------------------------

- (void)dealloc
{
	[super dealloc];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method stringForObjectValue
//	--------------------------------------------------------------------------------------------------------------------
/*
- (NSString *)stringForObjectValue:(id)anObject 
{	
    if (![anObject isKindOfClass:[NSNumber class]]) 
	{
        return nil;
    }
    
	return [NSString stringWithFormat:@"$%.2f", [anObject  floatValue]];
}
*/
//	--------------------------------------------------------------------------------------------------------------------
//	method stringForObjectValue
//	--------------------------------------------------------------------------------------------------------------------
/*
- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString  **)error 
{	     
	BOOL returnValue = NO;
	
	NSScanner *scanner = [NSScanner scannerWithString: string];
	
    [scanner scanString: @"$" intoString: NULL];    //ignore  return value
    
	float floatResult;

	if ([scanner scanFloat:&floatResult] && ([scanner isAtEnd])) 
	{
        returnValue = YES;
		
        if (obj)
        {    
			*obj = [NSNumber numberWithFloat:floatResult];
		}
		
    } 
	else 
	{
        if (error)
		{
            *error = NSLocalizedString(@"Couldn’t convert  to float", @"Error converting");
		}
    }
	
    return returnValue;
}
*/
//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------