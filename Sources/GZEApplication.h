//	--------------------------------------------------------------------------------------------------------------------
//
//  APNSTestAppDelegate.h
//  APNSTest
//
//  Created by Gerd Van Zegbroeck on 16/11/10.
//  Copyright 2010 Managing Software. All rights reserved.
//
//	--------------------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

//	--------------------------------------------------------------------------------------------------------------------
//	class references
//	--------------------------------------------------------------------------------------------------------------------

@class AsyncSocket;

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEApplication
//	--------------------------------------------------------------------------------------------------------------------

@interface GZEApplication : NSObject <NSApplicationDelegate> 
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

	NSButton *buttonPost;

	NSMutableArray *certificates;

	NSMutableArray *notificationIDs;
	
	AsyncSocket *asyncSocket;
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

@property (assign) IBOutlet NSButton *buttonPost;

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

- (IBAction)clickPost:(NSButton *)aSender;

- (IBAction)clickHelp:(NSButton *)aSender;

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------