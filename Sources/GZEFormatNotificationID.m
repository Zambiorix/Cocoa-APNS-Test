//	--------------------------------------------------------------------------------------------------------------------
//
//  GZEFormatNotificationID.m
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

#import "GZEFormatNotificationID.h"

//	--------------------------------------------------------------------------------------------------------------------
//	defines
//	--------------------------------------------------------------------------------------------------------------------

#define VALID_FORMAT	@"%08x-%08x-%08x-%08x-%08x-%08x-%08x-%08x"

#define VALID_COUNT		8

#define VALID_LENGTH	8

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatNotificationID
//	--------------------------------------------------------------------------------------------------------------------

@implementation GZEFormatNotificationID

//	--------------------------------------------------------------------------------------------------------------------
//	method arrayForString
//	--------------------------------------------------------------------------------------------------------------------

- (NSArray *)arrayForString:(NSString *)aString
{
	NSCharacterSet *keepCharacters = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
	
	unichar cZero = '0';
	
	NSUInteger characterIndex = 0;
	
	NSMutableString *string = [NSMutableString string];
	
	for (NSUInteger index = 0; index < (VALID_COUNT * VALID_LENGTH); index++)
	{		
		unichar c = cZero;
		
		while (characterIndex < aString.length)
		{
			c = [aString characterAtIndex:characterIndex++];
			
			if ([keepCharacters characterIsMember:c])
			{				
				break;
			}
			else 
			{
				c = cZero;
			}
		}
		
		[string appendString:[NSString stringWithCharacters:&c length:1]];
		
		if ((index % VALID_LENGTH) == (VALID_LENGTH - 1))
		{
			[string appendString:@" "];
		}
	}
	
	unsigned int number[VALID_COUNT] = { 0, 0, 0, 0, 0, 0, 0, 0 };
	
	NSScanner *scanner = [NSScanner scannerWithString:[string lowercaseString]];
	
	NSUInteger index = 0;
	
	while (![scanner isAtEnd] && (index < VALID_COUNT)) 
	{
		if (![scanner scanHexInt:&number[index++]])
		{
			break;
		}		
	}
	
	return [NSArray arrayWithObjects:
			
			[NSNumber numberWithUnsignedInt:number[0]],
			
			[NSNumber numberWithUnsignedInt:number[1]],
			
			[NSNumber numberWithUnsignedInt:number[2]],
			
			[NSNumber numberWithUnsignedInt:number[3]],
			
			[NSNumber numberWithUnsignedInt:number[4]],
			
			[NSNumber numberWithUnsignedInt:number[5]],
			
			[NSNumber numberWithUnsignedInt:number[6]],
			
			[NSNumber numberWithUnsignedInt:number[7]],
			
			nil];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method arrayForString
//	--------------------------------------------------------------------------------------------------------------------

+ (NSArray *)arrayForString:(NSString *)aString
{
	NSArray *result;
	
	GZEFormatNotificationID *formatter = [[self alloc] init];
	
	result = [formatter arrayForString:aString];
	
	[formatter release];
	
	return result;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method stringForObjectValue
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)stringForObjectValue:(id)aObject 
{ 
	NSArray *data = [NSArray arrayWithObjects:
					 
					 [NSNumber numberWithUnsignedInt:0],

					 [NSNumber numberWithUnsignedInt:0],

					 [NSNumber numberWithUnsignedInt:0],

					 [NSNumber numberWithUnsignedInt:0],

					 [NSNumber numberWithUnsignedInt:0],

					 [NSNumber numberWithUnsignedInt:0],

					 [NSNumber numberWithUnsignedInt:0],

					 [NSNumber numberWithUnsignedInt:0],

					 nil];
	
	if ([aObject isKindOfClass:[NSArray class]]) 
	{ 
		NSMutableArray *temp = [NSMutableArray arrayWithArray:aObject];
		
		for (NSUInteger index = 0; index < 8; index++)
		{
			if (temp.count > index)
			{
				if (![[temp objectAtIndex:index] isKindOfClass:[NSNumber class]])
				{
					[temp replaceObjectAtIndex:index withObject:[NSNumber numberWithUnsignedInt:0]];
				}
			}
			else 
			{
				[temp addObject:[NSNumber numberWithUnsignedInt:0]];
			}
		}
				
		data = temp;
	} 
	
	return [NSString stringWithFormat:VALID_FORMAT, 
			
			[[data objectAtIndex:0] unsignedIntValue],

			[[data objectAtIndex:1] unsignedIntValue],
			
			[[data objectAtIndex:2] unsignedIntValue],

			[[data objectAtIndex:3] unsignedIntValue],

			[[data objectAtIndex:4] unsignedIntValue],

			[[data objectAtIndex:5] unsignedIntValue],

			[[data objectAtIndex:6] unsignedIntValue],

			[[data objectAtIndex:7] unsignedIntValue]]; 
} 

//	--------------------------------------------------------------------------------------------------------------------
//	method getObjectValue forString errorDescription
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)getObjectValue:(id *)aObject 
			 
			 forString:(NSString *)aString 
	  
	  errorDescription:(NSString **)aError 
{ 	
	*aObject = [self arrayForString:aString];
	
	if (aError)
	{
		*aError = nil;
	}
		
	return YES;	
} 

//	--------------------------------------------------------------------------------------------------------------------
//	method isPartialStringValid newEditingString errorDescription
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)isPartialStringValid:(NSString **)aPartialString 
	   
	   proposedSelectedRange:(NSRangePointer)aProposedSelectedRange 
			  
			  originalString:(NSString *)aOriginalString 
	   
	   originalSelectedRange:(NSRange)aOriginalSelectedRange 
			
			errorDescription:(NSString **)aError
{
	NSRange proposedSelectedRange = (aProposedSelectedRange != nil) ? *aProposedSelectedRange : NSMakeRange(0, 0);
	
//	NSRange replaceSubStringRange = NSMakeRange(aOriginalSelectedRange.location, proposedSelectedRange.location - aOriginalSelectedRange.location);

//	NSString *replaceSubstring = [*aPartialString substringWithRange:replaceSubStringRange];
	
//	NSString *originalStringSelected = [aOriginalString substringWithRange:aOriginalSelectedRange];
	
	NSString *string = [self stringForObjectValue:[self arrayForString:*aPartialString]];
	
	//	TODO	calculate correct proposed selected range
	
	if (proposedSelectedRange.location > string.length)
	{
		proposedSelectedRange.location = string.length;
	}	
/*
	NSLog(@"---------------------------------------------------------------------------------------------------------");
	
	NSLog(@"original string            : %@", aOriginalString);

	NSLog(@"original substring         : %@", originalStringSelected);

	NSLog(@"original substring range   : %d - %d", aOriginalSelectedRange.location , aOriginalSelectedRange.length);

	NSLog(@"partial string             : %@", *aPartialString);

	NSLog(@"replace substring          : %@", replaceSubstring);

	NSLog(@"replace substring range    : %d - %d", replaceSubStringRange.location , replaceSubStringRange.length);
	
	NSLog(@"finale                     : %@", string);

	NSLog(@"final selected range       : %d - %d", proposedSelectedRange.location, proposedSelectedRange.length);

	NSLog(@"---------------------------------------------------------------------------------------------------------");
*/		
	*aPartialString = string;
		
	*aProposedSelectedRange = proposedSelectedRange;
	
	if (aError)
	{
		*aError = nil;
	}
	
	return NO; 
}

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------