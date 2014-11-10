//
//  GZEFormatCategory.h
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

#import <Foundation/Foundation.h>

//	--------------------------------------------------------------------------------------------------------------------
//	class references
//	--------------------------------------------------------------------------------------------------------------------

@class GZEFormatCategory;

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatCategoryDelegate
//	--------------------------------------------------------------------------------------------------------------------

@protocol GZEFormatCategoryDelegate

@required

- (BOOL)formatCategoryCheck:(GZEFormatCategory *)aCategory forString:(NSString *)aString;

@end

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatCategory
//	--------------------------------------------------------------------------------------------------------------------

@interface GZEFormatCategory : NSFormatter
{
@private
	
	id<GZEFormatCategoryDelegate> delegate;
}

//	--------------------------------------------------------------------------------------------------------------------
//	properties
//	--------------------------------------------------------------------------------------------------------------------

@property (assign) IBOutlet id<GZEFormatCategoryDelegate> delegate;

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------