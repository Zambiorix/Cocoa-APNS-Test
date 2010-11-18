//	--------------------------------------------------------------------------------------------------------------------
//
//  GZEFormatSound.h
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
//	class references
//	--------------------------------------------------------------------------------------------------------------------

@class GZEFormatSound;

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatSoundDelegate
//	--------------------------------------------------------------------------------------------------------------------

@protocol GZEFormatSoundDelegate

@required

- (BOOL)formatSoundCheck:(GZEFormatSound *)aSound forString:(NSString *)aString;

@end

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEFormatSound
//	--------------------------------------------------------------------------------------------------------------------

@interface GZEFormatSound : NSFormatter 
{
@private
	
	id<GZEFormatSoundDelegate> delegate;
}

//	--------------------------------------------------------------------------------------------------------------------
//	properties
//	--------------------------------------------------------------------------------------------------------------------

@property (assign) IBOutlet id<GZEFormatSoundDelegate> delegate;

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------