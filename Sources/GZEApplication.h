//	--------------------------------------------------------------------------------------------------------------------
//
//  APNSTestAppDelegate.h
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

#import <Cocoa/Cocoa.h>

#import "GZEFormatNotificationID.h"

#import "GZEFormatAlert.h"

#import "GZEFormatBadge.h"

#import "GZEFormatSound.h"

#import "GZEFormatCategory.h"

//	--------------------------------------------------------------------------------------------------------------------
//	class references
//	--------------------------------------------------------------------------------------------------------------------

@class GZECertificate;

@class AsyncSocket;

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEApplication
//	--------------------------------------------------------------------------------------------------------------------

@interface GZEApplication : NSObject 
<
	NSApplicationDelegate, GZEFormatAlertDelegate, GZEFormatBadgeDelegate, GZEFormatSoundDelegate, GZEFormatCategoryDelegate
> 
{

@private
	
    NSWindow *window;
	
	NSButton *buttonConnect;

	NSButton *buttonDisconnect;

	NSComboBox *comboBoxCertificate;
		
	NSButton *buttonSandbox;
	
	NSTableView *tableViewNotificationIDs;
	
	NSButton *buttonAddNotificationID;
	
	NSButton *buttonDeleteNotificationID;
	
	NSButton *buttonAlert;
	
	NSTextField *textFieldAlert;

	NSButton *buttonBadge;

	NSTextField *textFieldBadge;

	NSButton *buttonSound;

	NSTextField *textFieldSound;
	
	NSButton *buttonCategory;
	
	NSTextField *textFieldCategory;
    
    NSButton *buttonContentAvailable;

	NSTextView *textViewOutput;
    
    NSTableView *tableViewCustomKeys;
	
	NSButton *buttonSendNotification;

	NSButton *buttonReceiveFeedback;

	NSTextField *textFieldFooter;

	NSDictionary *textViewOutputAttributes;
	
	GZECertificate *currentCertificate;
	
	NSMutableArray *certificates;

	NSMutableArray *notificationIDs;
    
    NSMutableArray *customValues;
	
	AsyncSocket *socketGateway;	

	AsyncSocket *socketFeedback;	
	
	NSTimer *feedbackTimer;
}

//	--------------------------------------------------------------------------------------------------------------------
//	properies
//	--------------------------------------------------------------------------------------------------------------------

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSButton *buttonConnect;

@property (assign) IBOutlet NSButton *buttonDisconnect;

@property (assign) IBOutlet NSComboBox *comboBoxCertificate;

@property (assign) IBOutlet NSButton *buttonSandbox;

@property (assign) IBOutlet NSTableView *tableViewNotificationIDs;

@property (assign) IBOutlet NSButton *buttonAddNotificationID;

@property (assign) IBOutlet NSButton *buttonDeleteNotificationID;

@property (assign) IBOutlet NSButton *buttonAlert;

@property (assign) IBOutlet NSTextField *textFieldAlert;

@property (assign) IBOutlet NSButton *buttonBadge;

@property (assign) IBOutlet NSTextField *textFieldBadge;

@property (assign) IBOutlet NSButton *buttonSound;

@property (assign) IBOutlet NSTextField *textFieldSound;

@property (assign) IBOutlet NSButton *buttonCategory;

@property (assign) IBOutlet NSTextField *textFieldCategory;

@property (assign) IBOutlet NSButton *buttonContentAvailable;

@property (assign) IBOutlet NSTextView *textViewOutput;

@property (assign) IBOutlet NSButton *buttonSendNotification;

@property (assign) IBOutlet NSButton *buttonReceiveFeedback;

@property (assign) IBOutlet NSTextField *textFieldFooter;

@property (assign) IBOutlet NSTableView *tableViewCustomKeys;

@property (assign) IBOutlet NSButton *buttonAddCustomKey;

@property (assign) IBOutlet NSButton *buttonDeleteCustomKey;

@property (assign) IBOutlet NSButton *buttonCustomKeys;

//	--------------------------------------------------------------------------------------------------------------------
//	action prototypes
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickConnect:(NSButton *)aSender;

- (IBAction)clickDisconnect:(NSButton *)aSender;

- (IBAction)clickSandbox:(NSButton *)aSender;

- (IBAction)clickAddNotificationID:(NSButton *)aSender;

- (IBAction)clickDeleteNotificationID:(NSButton *)aSender;

- (IBAction)clickAlert:(NSButton *)aSender;

- (IBAction)clickBadge:(NSButton *)aSender;

- (IBAction)clickSound:(NSButton *)aSender;

- (IBAction)clickCategory:(NSButton *)sender;

- (IBAction)clickContentAvailable:(NSButton *)aSender;

- (IBAction)clickSendNotification:(NSButton *)aSender;

- (IBAction)clickReceiveFeedback:(NSButton *)aSender;

- (IBAction)clickHelp:(NSButton *)aSender;

- (IBAction)clickAddCustomKey:(NSButton*)sender;

- (IBAction)clickDeleteCustomKey:(NSButton*)sender;

- (IBAction)clickCustomKeys:(NSButton*)sender;

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------