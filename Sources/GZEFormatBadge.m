//	--------------------------------------------------------------------------------------------------------------------
//
//  GZEFormatBadge.m
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

#import "GZEFormatBadge.h"

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatBadge
//	--------------------------------------------------------------------------------------------------------------------

@implementation GZEFormatBadge

//	--------------------------------------------------------------------------------------------------------------------
//	property synthesizers
//	--------------------------------------------------------------------------------------------------------------------

@synthesize delegate;

//	--------------------------------------------------------------------------------------------------------------------
//	method isPartialStringValid newEditingString errorDescription
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)isPartialStringValid:(NSString *)aPartialString 
			
			newEditingString:(NSString **)aNewString 
			
			errorDescription:(NSString **)aError
{
	BOOL result = [super isPartialStringValid:aPartialString newEditingString:aNewString errorDescription:aError];
	
	if (result)
	{
		aPartialString = [aPartialString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		NSScanner *scanner = [NSScanner scannerWithString:aPartialString];
		
		NSInteger value = 0;

		result = [scanner scanInteger:&value];
		
		if (result)
		{
			if ([scanner isAtEnd])
			{
				if (value < 0) 
				{
					result = NO;
				}
				
				if (value > 999) 
				{
					result = NO;
				}
			}
			else 
			{
				result = NO;
			}			
		}
		else 
		{
			result = (aPartialString.length == 0);
		}
	}

	if (result && delegate)
	{
		NSUInteger value = [aPartialString intValue];
		
		return [delegate formatBadgeCheck:self forString:[NSString stringWithFormat:@"%d", value]];
	}
	
	return result;
}

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------