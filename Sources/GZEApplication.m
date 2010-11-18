//	--------------------------------------------------------------------------------------------------------------------
//
//  APNSTestAppDelegate.m
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

#import "GZEApplication.h"

#import "GZECertificate.h"

#import "AsyncSocket.h"

//	--------------------------------------------------------------------------------------------------------------------
//	defines
//	--------------------------------------------------------------------------------------------------------------------

#define APNS_DEVELOPMENT			@"Apple Development Push Services"

#define APNS_PRODUCTION				@"Apple Production Push Services"

#define HOST_GW_DEVELOPMENT			@"gateway.sandbox.push.apple.com"

#define HOST_GW_PRODUCTION			@"gateway.push.apple.com"

#define PORT_GW_DEVELOPMENT			2195

#define PORT_GW_PRODUCTION			2195

#define HOST_FB_DEVELOPMENT			@"feedback.sandbox.push.apple.com"

#define HOST_FB_PRODUCTION			@"feedback.push.apple.com"

#define PORT_FB_DEVELOPMENT			2196

#define PORT_FB_PRODUCTION			2196

#define DEFAULT_TIMEOUT				10.0f

#define DEFAULT_NOTIFICATION_ID		@"00000000-00000000-00000000-00000000-00000000-00000000-00000000-00000000"

#define DEFAULT_NOTIFICATION_NAME	@"?"

#define JSON_FORMAT					@"{\"aps\":{%@}}"

#define JSON_ALERT_FORMAT			@"\"alert\":\"%@\""

#define JSON_BADGE_FORMAT			@"\"badge\":%d"

#define JSON_SOUND_FORMAT			@"\"sound\":\"%@\""

#define JSON_MAX_PAYLOAD			256

#define PAYLOAD_FORMAT				@"Payload size : %d / %d"

//	--------------------------------------------------------------------------------------------------------------------
//	defines
//	--------------------------------------------------------------------------------------------------------------------

#define KEY_CERTIFICATE				@"kCertificate"

#define KEY_SELECTED				@"kSelected"

#define KEY_NAME					@"kName"

#define KEY_NOTIFICATION_ID			@"kNotificationID"

#define KEY_SANDBOX					@"kSandbox"

#define KEY_ALERT_ENABLED			@"kAlertEnabled"

#define KEY_ALERT					@"kAlert"

#define KEY_BADGE_ENABLED			@"kBadgeEnabled"

#define KEY_BADGE					@"kBadge"

#define KEY_SOUND_ENABLED			@"kSoundEnabled"

#define KEY_SOUND					@"kSound"

#define KEY_HELP_APNS				@"kHelpAPNS"

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEApplication
//	--------------------------------------------------------------------------------------------------------------------

@interface GZEApplication (Private)

- (NSString *)buildPayloadWithAlert:(NSString *)aAlert withBadge:(NSString *)aBadge withSound:(NSString *)aSound;

- (NSAttributedString *)buildFormattedPayload:(NSString *)aPayload;

@end

//	--------------------------------------------------------------------------------------------------------------------
//	class GZEApplication
//	--------------------------------------------------------------------------------------------------------------------

@implementation GZEApplication

//	--------------------------------------------------------------------------------------------------------------------
//	property synthesizers
//	--------------------------------------------------------------------------------------------------------------------

@synthesize window;

@synthesize buttonConnect;

@synthesize buttonDisconnect;

@synthesize comboBoxCertificate;

@synthesize buttonSandbox;

@synthesize tableViewNotificationIDs;

@synthesize buttonAddNotificationID;

@synthesize buttonDeleteNotificationID;

@synthesize buttonAlert;

@synthesize textFieldAlert;

@synthesize buttonBadge;

@synthesize textFieldBadge;

@synthesize buttonSound;

@synthesize textFieldSound;

@synthesize textViewOutput;

@synthesize buttonSendNotification;

@synthesize textFieldFooter;

//	--------------------------------------------------------------------------------------------------------------------
//	method getAttribute
//	--------------------------------------------------------------------------------------------------------------------

- (NSData *)getAttribute:(SecKeychainAttrType)aAttribute ofItem:(SecKeyRef)aItem 
{
    NSData *value = nil;
	
	UInt32 format = kSecFormatUnknown;
	
	SecKeychainAttributeInfo info = {.count = 1, .tag = (UInt32*)&aAttribute, .format = &format};
    
	SecKeychainAttributeList *list = NULL;
	
    if (SecKeychainItemCopyAttributesAndData((SecKeychainItemRef)aItem, &info, NULL, &list, NULL, NULL) == noErr) 
	{
        if (list) 
		{
            if (list->count == 1)
			{
                value = [NSData dataWithBytes:list->attr->data length:list->attr->length];
			}
			
            SecKeychainItemFreeAttributesAndData(list, NULL);
        }
    }

    return value;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method getStringAttribute
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)getStringAttribute:(SecKeychainAttrType)aAttribute ofItem:(SecKeyRef)aItem 
{
    NSData *value = [self getAttribute:aAttribute ofItem:aItem];
	
    if (value)
	{
		const char *bytes = value.bytes;

		size_t length = value.length;
		
		if ((length > 0) && (bytes[length - 1] == 0))
		{
			length--;        
		}
		
		NSString *string = [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
		
		return [string autorelease];
	}
	
	return nil;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method loadCertificates
//	--------------------------------------------------------------------------------------------------------------------

- (void)loadCertificates:(NSMutableArray *)aCertificates
{
	[aCertificates removeAllObjects];
	
	SecKeychainRef keychainRef = nil;
	
	if (SecKeychainCopyDefault(&keychainRef) == noErr)
	{
		SecIdentitySearchRef searchRef = nil;
		
		if (SecIdentitySearchCreate(keychainRef, CSSM_KEYUSE_DECRYPT, &searchRef) == noErr)
		{
			SecIdentityRef identityRef = nil;	//	this is the return value
			
			while (SecIdentitySearchCopyNext(searchRef, &identityRef) != errSecItemNotFound) 
			{
				BOOL includeCertificate = NO;
				
				SecCertificateRef certificateRef = nil;
								
				if (SecIdentityCopyCertificate(identityRef, &certificateRef) == noErr) 
				{
					CFStringRef commonName = nil;
					
					if (SecCertificateCopyCommonName(certificateRef, &commonName) == noErr) 
					{
						BOOL isSandbox = (self.buttonSandbox.state == NSOnState);

						if (isSandbox)
						{
							includeCertificate = [(NSString *)commonName hasPrefix:APNS_DEVELOPMENT];
						}
						else
						{
							includeCertificate = [(NSString *)commonName hasPrefix:APNS_PRODUCTION];
						}
				
						if (includeCertificate)
						{
							SecKeyRef privateRef = nil;
							
							if (SecIdentityCopyPrivateKey(identityRef, &privateRef) == noErr)
							{
								NSString *name = [self getStringAttribute:kSecKeyPrintName ofItem:privateRef];
								
								[aCertificates addObject:[GZECertificate certificateWithKey:(NSString *)commonName 
														  
																				   withName:name 
														  
																			   withIdentity:identityRef]];		
								
								CFRelease(privateRef);				
							}
						}
												
						CFRelease(commonName);
					}
					
					CFRelease(certificateRef);
				}
												
				CFRelease(identityRef);				
			}
			
			CFRelease(searchRef);
		}
		
		CFRelease(keychainRef);
	}
}

//	--------------------------------------------------------------------------------------------------------------------
//	method updateStatus
//	--------------------------------------------------------------------------------------------------------------------

- (void)updateStatus
{
	BOOL hasNoSocket = (socketGateway == nil);
			
	BOOL hasCertificate = ([comboBoxCertificate indexOfSelectedItem] >= 0);

	BOOL hasNotificationIDs = (notificationIDs != nil);

	BOOL hasNotificationIDsSelected = ([tableViewNotificationIDs numberOfSelectedRows] > 0);

	BOOL hasNotificationIDsToSend = NO;
	
	for (NSDictionary *data in notificationIDs)
	{
		if ([(NSNumber *)[data objectForKey:KEY_SELECTED] boolValue])
		{
			hasNotificationIDsToSend = YES;
			
			break;
		}
	}		
	
	[buttonConnect setEnabled:hasNoSocket && hasCertificate];

	[buttonDisconnect setEnabled:!hasNoSocket];
			
	[comboBoxCertificate setEnabled:hasNoSocket];

	[buttonSandbox setEnabled:hasNoSocket];

	[tableViewNotificationIDs setEnabled:hasNotificationIDs];
	
	[buttonAddNotificationID setEnabled:hasNotificationIDs];
	
	[buttonDeleteNotificationID setEnabled:hasNotificationIDs && hasNotificationIDsSelected];
	
	[textFieldAlert setEnabled:(buttonAlert.state == NSOnState)];

	[textFieldBadge setEnabled:(buttonBadge.state == NSOnState)];

	[textFieldSound setEnabled:(buttonSound.state == NSOnState)];

	[buttonSendNotification setEnabled:!hasNoSocket && hasNotificationIDsToSend];

	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue 
						 
										  withBadge:textFieldBadge.stringValue 
						 
										  withSound:textFieldSound.stringValue];
		
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
		
	textFieldFooter.stringValue = [NSString stringWithFormat:PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD - 1];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method applicationDidFinishLaunching
//	--------------------------------------------------------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{		
	//	register defaults
	
	NSString *defaultsFile = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
	
	NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:defaultsFile];
	
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];	
		
	//	loading defaults : sandbox
	
	BOOL isSandbox = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_SANDBOX];

	buttonSandbox.state = isSandbox ? NSOnState : NSOffState;

	//	initialize certificates
	
	certificates = [[NSMutableArray alloc] init];
	
	[self loadCertificates:certificates];
	
	[comboBoxCertificate reloadData];
	
	//	loading defaults : certificate
	
	currentCertificate = nil;

	NSString *certificateKey = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_CERTIFICATE];
	
	for (NSUInteger index = 0; index < certificates.count; index++)
	{
		GZECertificate *certificate = [certificates objectAtIndex:index];
		
		if ([certificate.key isEqualToString:certificateKey])
		{
			[comboBoxCertificate selectItemAtIndex:index];
			
			currentCertificate = certificate;
			
			break;
		}
	}
	
	//	notification id's
	
	notificationIDs = nil;
	
	if (currentCertificate)
	{
		NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:currentCertificate.key];
		
		notificationIDs = (NSMutableArray *)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, 
																		 
																		 (CFPropertyListRef)array, 
																		 
																		 kCFPropertyListMutableContainers);				
		if (!notificationIDs)
		{
			notificationIDs = [[NSMutableArray alloc] init];
						
			[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:currentCertificate.key];
		}
	}
	
	[tableViewNotificationIDs reloadData];
	
	//	loading defaults : alert

	BOOL isAlert = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_ALERT_ENABLED];
	
	buttonAlert.state =  isAlert ? NSOnState : NSOffState;
	
	textFieldAlert.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_ALERT];

	//	loading defaults : badge

	BOOL isBadge = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_BADGE_ENABLED];
	
	buttonBadge.state =  isBadge ? NSOnState : NSOffState;
		
	textFieldBadge.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_BADGE];

	//	loading defaults : sound

	BOOL isSound = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_SOUND_ENABLED];
	
	buttonSound.state =  isSound ? NSOnState : NSOffState;
	
	textFieldSound.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_SOUND];
	
	//	register drag types
	
	[tableViewNotificationIDs registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];
	
	//	update status
	
	[self updateStatus];
	
	//	window
	
	[window center];	
	
	[window makeKeyAndOrderFront:self];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method applicationWillTerminate
//	--------------------------------------------------------------------------------------------------------------------

- (void)applicationWillTerminate:(NSNotification *)aNotification
{		
	//	cleanup socket gateway
	
	[socketGateway setDelegate:nil];
	
	[socketGateway disconnect];
	
	[socketGateway release]; socketGateway = nil;

	//	cleanup socket feedback
	
	[socketFeedback setDelegate:nil];
	
	[socketFeedback disconnect];
	
	[socketFeedback release]; socketFeedback = nil;
	
	//	cleanup feedback timer
	
	[feedbackTimer invalidate]; feedbackTimer = nil;
	
	//	cleanup certificates & notification id's
	
	[certificates release]; certificates = nil;
	
	[notificationIDs release]; notificationIDs = nil;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method applicationShouldTerminateAfterLastWindowClosed
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method numberOfItemsInComboBox
//	--------------------------------------------------------------------------------------------------------------------

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return certificates.count;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method comboBoxSelectionDidChange
//	--------------------------------------------------------------------------------------------------------------------

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{	
	//	store certificate defaults
	
	NSUInteger index = comboBoxCertificate.indexOfSelectedItem;

	currentCertificate = (index >= 0) ? [certificates objectAtIndex:index] : nil;
		
	id object = currentCertificate ? [currentCertificate key] : @"";
	
	[[NSUserDefaults standardUserDefaults] setObject:object forKey:KEY_CERTIFICATE];
	
	//	notification id's

	[notificationIDs release]; notificationIDs = nil;
	
	if (currentCertificate)
	{
		NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:currentCertificate.key];
		
		notificationIDs = (NSMutableArray *)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, 
																		 
																		 (CFPropertyListRef)array, 
																		 
																		 kCFPropertyListMutableContainers);				
		if (!notificationIDs)
		{
			notificationIDs = [[NSMutableArray alloc] init];
			
			[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:currentCertificate.key];
		}
	}
	
	[tableViewNotificationIDs reloadData];
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method comboBox objectValueForItemAtIndex
//	--------------------------------------------------------------------------------------------------------------------

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	GZECertificate *certifcate = [certificates objectAtIndex:index];
	
	return certifcate.name;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method numberOfRowsInTableView
//	--------------------------------------------------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    return notificationIDs ? notificationIDs.count : 0;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableView objectValueForTableColumn
//	--------------------------------------------------------------------------------------------------------------------

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row 
{	
	return [[notificationIDs objectAtIndex:row] objectForKey:[column identifier]];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableView setObjectValue
//	--------------------------------------------------------------------------------------------------------------------

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(NSInteger)row 
{ 	
	if ([[column identifier] isEqualToString:KEY_NOTIFICATION_ID])
	{		
		if ([value isKindOfClass:[NSString class]])
		{
			value = [GZEFormatNotificationID arrayForString:value];
		}
	}
		
	[[notificationIDs objectAtIndex:row] setObject:value forKey:[column identifier]];

	[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:currentCertificate.key];

	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableViewSelectionDidChange
//	--------------------------------------------------------------------------------------------------------------------

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableView validateDrop validateDrop proposedRow proposedDropOperation
//	--------------------------------------------------------------------------------------------------------------------

- (NSDragOperation)tableView:(NSTableView*)tv 
				
				validateDrop:(id<NSDraggingInfo>)info 
				 
				 proposedRow:(NSInteger)row 
	   
	   proposedDropOperation:(NSTableViewDropOperation)operation
{
	//	TODO	validate input
	
    return NSDragOperationEvery;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableView acceptDrop validateDrop proposedRow proposedDropOperation
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)tableView:(NSTableView *)aTableView 
	   
	   acceptDrop:(id<NSDraggingInfo>)info

			  row:(NSInteger)row 
	
	dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard = [info draggingPasteboard];
	
    NSString *dropped = [pboard stringForType:NSPasteboardTypeString];
		
	NSArray *array = [GZEFormatNotificationID arrayForString:dropped];
			
	switch (operation) 
	{
		case NSTableViewDropOn:
		{
			NSMutableDictionary *data = [notificationIDs objectAtIndex:row];
			
			[data setObject:array forKey:KEY_NOTIFICATION_ID];
			
			NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:row];
			
			[tableViewNotificationIDs reloadData];
			
			[tableViewNotificationIDs selectRowIndexes:indexes byExtendingSelection:NO];

			[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:currentCertificate.key];

			break;
		}

		case NSTableViewDropAbove:
		{
			NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										 
										 [NSNumber numberWithBool:NO],		KEY_SELECTED,
										 
										 DEFAULT_NOTIFICATION_NAME,			KEY_NAME,
										 
										 array,								KEY_NOTIFICATION_ID,
										 
										 nil];
			
			[notificationIDs insertObject:data atIndex:row];
			
			NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:row];
			
			[tableViewNotificationIDs reloadData];
			
			[tableViewNotificationIDs selectRowIndexes:indexes byExtendingSelection:NO];
			
			[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:currentCertificate.key];

			break;
		}
	}
	
	//	update status
	
	[self updateStatus];

	//	done
	
	return YES;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method buildNotificationID onLocation
//	--------------------------------------------------------------------------------------------------------------------

- (NSUInteger)buildNotificationID:(NSArray *)aNotificationID onLocation:(unsigned int *)aLocation
{	
	for (NSUInteger index = 0; index < 8; index++)
	{
		NSNumber *number = [aNotificationID objectAtIndex:index];
		
		aLocation[index] = NSSwapInt([number intValue]);		
	}
			
	return 32;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method buildPayloadWithAlert withBadge withSound
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)buildPayloadWithAlert:(NSString *)aAlert withBadge:(NSString *)aBadge withSound:(NSString *)aSound
{
	//	payload : alert
	
	NSString *plAlert = nil;
	
	if (buttonAlert.state == NSOnState)
	{
		plAlert = [NSString stringWithFormat:JSON_ALERT_FORMAT, aAlert];
	}
	
	//	payload : badge
	
	NSString *plBadge = nil;
	
	if (buttonBadge.state == NSOnState)
	{			
		plBadge = [NSString stringWithFormat:JSON_BADGE_FORMAT, aBadge.intValue];
	}
	
	//	payload : sound
	
	NSString *plSound = nil;
	
	if (buttonSound.state == NSOnState)
	{		
		plSound = [NSString stringWithFormat:JSON_SOUND_FORMAT, aSound];
	}
	
	//	payload
	
	NSMutableString *payloadAPS = [NSMutableString string];
	
	if (plAlert)
	{
		if (payloadAPS.length > 0)
		{
			[payloadAPS appendFormat:@",%@", plAlert];
		}
		else 
		{
			[payloadAPS appendFormat:@"%@", plAlert];
		}
	}
	
	if (plBadge)
	{
		if (payloadAPS.length > 0)
		{
			[payloadAPS appendFormat:@",%@", plBadge];
		}
		else 
		{
			[payloadAPS appendFormat:@"%@", plBadge];
		}
	}
	
	if (plSound)
	{
		if (payloadAPS.length > 0)
		{
			[payloadAPS appendFormat:@",%@", plSound];
		}
		else 
		{
			[payloadAPS appendFormat:@"%@", plSound];
		}
	}
	
	NSString *payload = [NSString stringWithFormat:JSON_FORMAT, payloadAPS];

	return payload;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method buildFormattedPayload
//	--------------------------------------------------------------------------------------------------------------------

- (NSAttributedString *)buildFormattedPayload:(NSString *)aPayload
{
	return [[[NSAttributedString alloc] initWithString:aPayload] autorelease];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method buildPayload
//	--------------------------------------------------------------------------------------------------------------------

- (NSUInteger)buildPayload:(NSMutableData *)aData
{	
	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue 
						 
										  withBadge:textFieldBadge.stringValue 
						 
										  withSound:textFieldSound.stringValue];
	
	const char *payloadChar = [payload cStringUsingEncoding:NSUTF8StringEncoding];
	
	NSUInteger length = strlen(payloadChar);
	
	[aData appendBytes:payloadChar length:length];
	
	return length;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method control isValidObject
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)control:(NSControl *)control isValidObject:(id)object
{
	if (control == textFieldAlert)
	{
		[[NSUserDefaults standardUserDefaults] setObject:object forKey:KEY_ALERT];
	}
	
	if (control == textFieldBadge)
	{
		[[NSUserDefaults standardUserDefaults] setObject:object forKey:KEY_BADGE];		
	}

	if (control == textFieldSound)
	{
		[[NSUserDefaults standardUserDefaults] setObject:object forKey:KEY_SOUND];
	}
	
	return YES;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method formatAlertCheck forString
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)formatAlertCheck:(GZEFormatAlert *)aAlert forString:(NSString *)aString
{	
	NSString *payload = [self buildPayloadWithAlert:aString 
										  
										  withBadge:textFieldBadge.stringValue 
										  
										  withSound:textFieldSound.stringValue];
		
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
	
	textFieldFooter.stringValue = [NSString stringWithFormat:PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD - 1];
	
	return (payload.length < JSON_MAX_PAYLOAD);
}

//	--------------------------------------------------------------------------------------------------------------------
//	method formatBadgeCheck forString
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)formatBadgeCheck:(GZEFormatBadge *)aBadge forString:(NSString *)aString
{
	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue 
						 
										  withBadge:aString 
						 
										  withSound:textFieldSound.stringValue];

	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
	
	textFieldFooter.stringValue = [NSString stringWithFormat:PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD - 1];
	
	return (payload.length < JSON_MAX_PAYLOAD);
}

//	--------------------------------------------------------------------------------------------------------------------
//	method formatSoundCheck forString
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)formatSoundCheck:(GZEFormatSound *)aSound forString:(NSString *)aString
{
	NSString *payload = [self buildPayloadWithAlert:textFieldSound.stringValue 
						 
										  withBadge:textFieldBadge.stringValue 
						 
										  withSound:aString];
	
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
	
	textFieldFooter.stringValue = [NSString stringWithFormat:PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD - 1];
	
	return (payload.length < JSON_MAX_PAYLOAD);
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickConnect
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickConnect:(NSButton *)aSender
{
	if (!socketGateway)
	{	
		NSLog(@"Socket GW : Connect");

		BOOL isSandbox = (self.buttonSandbox.state == NSOnState);
		
		NSString *host = isSandbox ? HOST_GW_DEVELOPMENT : HOST_GW_PRODUCTION;
		
		NSUInteger port = isSandbox ? PORT_GW_DEVELOPMENT : PORT_GW_PRODUCTION; 
		
		//	create socket
		
		socketGateway = [[AsyncSocket alloc] initWithDelegate:self];
		
		if (![socketGateway connectToHost:host onPort:port error:nil])
		{
			[socketGateway disconnect];
			
			[socketGateway release]; socketGateway = nil;
		}
	}
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickDisconnect
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickDisconnect:(NSButton *)aSender
{
	//	cleanup socket gateway
	
	if (socketGateway)
	{
		[socketGateway disconnect];
		
		[socketGateway autorelease]; socketGateway = nil;
	}

	//	cleanup socket feedback

	if (socketFeedback)
	{
		[socketFeedback disconnect];
		
		[socketFeedback autorelease]; socketFeedback = nil;
	}

	//	cleanup feedback timer
	
	[feedbackTimer invalidate]; feedbackTimer = nil;
	
	//	update status

	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickSandbox
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickSandbox:(NSButton *)aSender
{	
	BOOL isEnabled = (buttonSandbox.state == NSOnState);

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isEnabled] forKey:KEY_SANDBOX];
			
	//	load certificates
	
	currentCertificate = nil;

	[self loadCertificates:certificates];
	
	[comboBoxCertificate setStringValue:@""];
	
	[comboBoxCertificate reloadData];
	
	//	cleanup notification id's
		
	[notificationIDs release]; notificationIDs = nil;
	
	[tableViewNotificationIDs reloadData];

	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickAddNotificationID
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickAddNotificationID:(NSButton *)aSender
{
	NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 
								 [NSNumber numberWithBool:NO],		KEY_SELECTED,
								 
								 DEFAULT_NOTIFICATION_NAME,			KEY_NAME,
								 
								 DEFAULT_NOTIFICATION_ID,			KEY_NOTIFICATION_ID,
								 
								 nil];
	
	[notificationIDs addObject:data];
	
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:(notificationIDs.count - 1)];

	[tableViewNotificationIDs reloadData];
		
	[tableViewNotificationIDs selectRowIndexes:indexes byExtendingSelection:NO];

	[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:currentCertificate.key];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickDeleteNotificationID
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickDeleteNotificationID:(NSButton *)aSender
{		
	[notificationIDs removeObjectsAtIndexes:[tableViewNotificationIDs selectedRowIndexes]];
	
	[tableViewNotificationIDs reloadData];

	[tableViewNotificationIDs selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];

	[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:currentCertificate.key];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickAlert
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickAlert:(NSButton *)aSender
{
	BOOL isEnabled = (buttonAlert.state == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isEnabled] forKey:KEY_ALERT_ENABLED];
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickBadge
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickBadge:(NSButton *)aSender
{
	BOOL isEnabled = (buttonBadge.state == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isEnabled] forKey:KEY_BADGE_ENABLED];
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickSound
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickSound:(NSButton *)aSender
{
	BOOL isEnabled = (buttonSound.state == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isEnabled] forKey:KEY_SOUND_ENABLED];
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickSendNotification
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickSendNotification:(NSButton *)aSender
{	
	for (NSDictionary *data in notificationIDs)
	{
		//	check if selected
		
		BOOL isSelected = [(NSNumber *)[data objectForKey:KEY_SELECTED] boolValue];
		
		if (!isSelected)
		{
			continue;
		}
								
		//	output 
		
		NSMutableData *output = [[NSMutableData alloc] init];

		NSMutableData *outputPayload = [[NSMutableData alloc] init];
				
		//	header
	
		char header[37];

		header[ 0] = 0;		//	fixed
		
		header[ 1] = 0;		//	fixed
		
		header[ 2] = [self buildNotificationID:[data objectForKey:KEY_NOTIFICATION_ID] onLocation:(unsigned int *)&header[3]];
						
		header[35] = 0;		//	fixed
		
		header[36] = [self buildPayload:outputPayload];
		
		//	prepare output buffer
		
		[output appendBytes:header length:sizeof(header)];
		
		[output appendData:outputPayload];
		
		//	send notification
							
		[socketGateway writeData:output withTimeout:DEFAULT_TIMEOUT tag:0];

		//	done
		
		[outputPayload release];
		
		[output release];
	}
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickHelp
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickHelp:(NSButton *)aSender
{
	NSString *urlString = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_HELP_APNS];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method timerFired
//	--------------------------------------------------------------------------------------------------------------------

- (void)timerFired:(NSTimer *)aTimer
{
	//	TODO	debug feedback service
	
/*	
	if (aTimer == feedbackTimer)
	{
		if (!socketFeedback)
		{	
			NSLog(@"Socket FB : Connect");
			
			BOOL isSandbox = (self.buttonSandbox.state == NSOnState);
			
			NSString *host = isSandbox ? HOST_FB_DEVELOPMENT : HOST_FB_PRODUCTION;
			
			NSUInteger port = isSandbox ? PORT_FB_DEVELOPMENT : PORT_FB_PRODUCTION; 
			
			//	create socket
			
			socketFeedback = [[AsyncSocket alloc] initWithDelegate:self];
			
			if (![socketFeedback connectToHost:host onPort:port error:nil])
			{
				[socketFeedback disconnect];
				
				[socketFeedback release]; socketFeedback = nil;
			}
		}
		
		//	update status
		
		[self updateStatus];
	}
*/
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket didConnectToHost
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{	
	if (sock == socketGateway)
	{
		//	connection established
		
		NSLog(@"Socket GW : Connected : %@ : %d", host, port);
	}	
	
	if (sock == socketFeedback)
	{
		//	connection established
		
		NSLog(@"Socket FB : Connected : %@ : %d", host, port);
	}
	
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	NSInteger index = [comboBoxCertificate indexOfSelectedItem];
	
	if (index >= 0)
	{
		GZECertificate *certificate = [certificates objectAtIndex:index];
				
		SecIdentityRef identity = [certificate identity];
		
		CFArrayRef arrayRef = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
		
		if (arrayRef)
		{
			[settings setObject:(NSArray *)arrayRef forKey:(NSString *)kCFStreamSSLCertificates];

			CFRelease(arrayRef);
		}
	}

	[sock startTLS:settings];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocketDidSecure
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocketDidSecure:(AsyncSocket *)sock
{
	if (sock == socketGateway)
	{
		//	start reading
		
		[socketGateway readDataWithTimeout:DEFAULT_TIMEOUT tag:0];

		//	start feedback timer
		
		feedbackTimer = [NSTimer scheduledTimerWithTimeInterval:60.0f 
						 
														 target:self 
						 
													   selector:@selector(timerFired:) 
						 
													   userInfo:nil 
						 
														repeats:YES];
		
		[self timerFired:feedbackTimer];
		
		//	connection established

		NSLog(@"Socket GW : Secured");
	}	
	
	if (sock == socketFeedback)
	{		
		//	start reading

		[socketFeedback readDataWithTimeout:DEFAULT_TIMEOUT tag:0];

		//	cleanup feedback timer
		
		[feedbackTimer invalidate]; feedbackTimer = nil;
		
		//	connection established

		NSLog(@"Socket FB : Secured");
	}
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket didReadData
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if (sock == socketGateway)
	{
		[socketGateway readDataWithTimeout:DEFAULT_TIMEOUT tag:0];
		
		NSLog(@"Socket GW : Read");
	}	

	if (sock == socketFeedback)
	{
		[socketFeedback readDataWithTimeout:DEFAULT_TIMEOUT tag:0];
		
		NSLog(@"Socket FB : Read");
	}	
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket shouldTimeoutReadWithTag elapsed bytesDone
//	--------------------------------------------------------------------------------------------------------------------

- (NSTimeInterval)onSocket:(AsyncSocket *)sock

  shouldTimeoutReadWithTag:(long)tag

				   elapsed:(NSTimeInterval)elapsed

				 bytesDone:(CFIndex)length
{
	return DEFAULT_TIMEOUT;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket willDisconnectWithError
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	if (sock == socketGateway)
	{
		NSLog(@"Socket GW : Error : %@", err);
	}	
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocketDidDisconnect
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	//	cleanup socket gateway
	
	if (sock == socketGateway)
	{				
		//	cleanup socket gateway
		
		[socketGateway setDelegate:nil];
		
		[socketGateway disconnect];
		
		[socketGateway release]; socketGateway = nil;

		//	cleanup socket feedback
		
		[socketFeedback setDelegate:nil];
		
		[socketFeedback disconnect];
		
		[socketFeedback release]; socketFeedback = nil;
	
		//	cleanup feedback timer
		
		[feedbackTimer invalidate]; feedbackTimer = nil;
		
		//	connection terminated
		
		NSLog(@"Socket GW : Terminated");
	}

	//	cleanup socket gateway
	
	if (sock == socketFeedback)
	{		
		//	cleanup socket feedback
		
		[socketFeedback setDelegate:nil];
		
		[socketFeedback disconnect];
		
		[socketFeedback release]; socketFeedback = nil;

		//	start feedback timer
		
		feedbackTimer = [NSTimer scheduledTimerWithTimeInterval:60.0f 
						 
														 target:self 
						 
													   selector:@selector(timerFired:) 
						 
													   userInfo:nil 
						 
														repeats:YES];
	
		//	connection terminated
		
		NSLog(@"Socket FB : Terminated");
	}
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------