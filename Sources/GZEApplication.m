//	--------------------------------------------------------------------------------------------------------------------
//
//  APNSTestAppDelegate.m
//  APNSTest
//
//  Created by Gerd Van Zegbroeck on 16/11/10.
//  Copyright 2010 Managing Software. All rights reserved.
//
//	--------------------------------------------------------------------------------------------------------------------

#import "GZEApplication.h"

#import "GZECertificate.h"

#import "AsyncSocket.h"

//	--------------------------------------------------------------------------------------------------------------------
//	defines
//	--------------------------------------------------------------------------------------------------------------------

#define KEY_DEVELOPMENT			@"Apple Development Push Services"

#define KEY_PRODUCTION			@"Apple Production Push Services"

#define HOST_DEVELOPMENT		@"gateway.sandbox.push.apple.com"

#define HOST_PRODUCTION			@"gateway.push.apple.com"

#define PORT_DEVELOPMENT		2195

#define PORT_PRODUCTION			2195

#define JSON_FORMAT				@"{\"aps\":{%@}}"

#define JSON_ALERT_FORMAT		@"\"alert\":\"%@\""

#define JSON_BADGE_FORMAT		@"\"badge\":%d"

#define JSON_SOUND_FORMAT		@"\"sound\":\"%@\""

//	--------------------------------------------------------------------------------------------------------------------

#define HELP @"http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG"

//	--------------------------------------------------------------------------------------------------------------------
//	defines
//	--------------------------------------------------------------------------------------------------------------------

#define KEY_SELECTED			@"kSelected"

#define KEY_NAME				@"kName"

#define KEY_NOTIFICATION_ID		@"kNotificationID"

#define KEY_NOTIFICATION_IDS	@"kNotificationIDs"

#define KEY_SANDBOX				@"kSandbox"

#define KEY_ALERT_ENABLED		@"kAlertEnabled"

#define KEY_ALERT				@"kAlert"

#define KEY_BADGE_ENABLED		@"kBadgeEnabled"

#define KEY_BADGE				@"kBadge"

#define KEY_SOUND_ENABLED		@"kSoundEnabled"

#define KEY_SOUND				@"kSound"

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

@synthesize buttonPost;

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
							includeCertificate = [(NSString *)commonName hasPrefix:KEY_DEVELOPMENT];
						}
						else
						{
							includeCertificate = [(NSString *)commonName hasPrefix:KEY_PRODUCTION];
						}
												
						CFRelease(commonName);
					}
					
					CFRelease(certificateRef);
				}
				
				if (includeCertificate)
				{
					SecKeyRef privateRef = nil;
					
					if (SecIdentityCopyPrivateKey(identityRef, &privateRef) == noErr)
					{
						NSString *name = [self getStringAttribute:kSecKeyPrintName ofItem:privateRef];

						[aCertificates addObject:[GZECertificate certificateWithName:name 
																		
																		withIdentity:identityRef]];		
					
						CFRelease(privateRef);				
					}
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
	BOOL hasNoSocket = (asyncSocket == nil);
			
	BOOL hasCertificate = ([comboBoxCertificate indexOfSelectedItem] >= 0);

	BOOL hasNotificationIDs = NO;
	
	for (NSDictionary *data in notificationIDs)
	{
		if ([(NSNumber *)[data objectForKey:KEY_SELECTED] boolValue])
		{
			hasNotificationIDs = YES;
			
			break;
		}
	}		
	
	[buttonConnect setEnabled:hasNoSocket && hasCertificate];

	[buttonDisconnect setEnabled:!hasNoSocket];
			
	[comboBoxCertificate setEnabled:hasNoSocket];

	[buttonSandbox setEnabled:hasNoSocket];

	[buttonAddNotificationID setEnabled:YES];
	
	[buttonDeleteNotificationID setEnabled:([tableViewNotificationIDs numberOfSelectedRows] > 0)];
	
	[textFieldAlert setEnabled:(buttonAlert.state == NSOnState)];

	[textFieldBadge setEnabled:(buttonBadge.state == NSOnState)];

	[textFieldSound setEnabled:(buttonSound.state == NSOnState)];

	[buttonPost setEnabled:!hasNoSocket && hasNotificationIDs];
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

	//	initialize certificates

	certificates = [[NSMutableArray alloc] init];
	
	[self loadCertificates:certificates];
	
	[comboBoxCertificate reloadData];
			
	//	initialize notification ids
			
	NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:KEY_NOTIFICATION_IDS];
	
	notificationIDs = (NSMutableArray *)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, 
																	 
																	 (CFPropertyListRef)array, 
																	 
																	 kCFPropertyListMutableContainers);		
	[tableViewNotificationIDs reloadData];
	
	//	register drag types
	
	[tableViewNotificationIDs registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];
	
	//	loading defaults : sandbox
	
	BOOL isSandbox = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_SANDBOX];

	buttonSandbox.state = isSandbox ? NSOnState : NSOffState;

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
	//	cleanup socket
	
	[asyncSocket setDelegate:nil];
	
	[asyncSocket disconnect];
	
	[asyncSocket release]; asyncSocket = nil;
	
	//	store defaults
	
	[[NSUserDefaults standardUserDefaults] setObject:textFieldAlert.stringValue forKey:KEY_ALERT];

	[[NSUserDefaults standardUserDefaults] setInteger:textFieldBadge.stringValue.intValue forKey:KEY_BADGE];

	[[NSUserDefaults standardUserDefaults] setObject:textFieldSound.stringValue forKey:KEY_SOUND];
	
	//	cleanup certificates & notification ids
	
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
    return notificationIDs.count;
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
	[[notificationIDs objectAtIndex:row] setObject:value forKey:[column identifier]];

	[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:KEY_NOTIFICATION_IDS];

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
	//	TODO	check input
	
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
		
	switch (operation) 
	{
		case NSTableViewDropOn:
		{
			NSMutableDictionary *data = [notificationIDs objectAtIndex:row];
			
			[data setObject:dropped forKey:KEY_NOTIFICATION_ID];
			
			NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:row];
			
			[tableViewNotificationIDs reloadData];
			
			[tableViewNotificationIDs selectRowIndexes:indexes byExtendingSelection:NO];

			[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:KEY_NOTIFICATION_IDS];

			break;
		}

		case NSTableViewDropAbove:
		{
			NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										 
										 [NSNumber numberWithBool:NO],		KEY_SELECTED,
										 
										 @"new",							KEY_NAME,
										 
										 dropped,							KEY_NOTIFICATION_ID,
										 
										 nil];
			
			[notificationIDs insertObject:data atIndex:row];
			
			NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:row];
			
			[tableViewNotificationIDs reloadData];
			
			[tableViewNotificationIDs selectRowIndexes:indexes byExtendingSelection:NO];
			
			[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:KEY_NOTIFICATION_IDS];

			break;
		}
	}
	
	//	update status
	
	[self updateStatus];

	//	done
	
	return YES;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickConnect
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickConnect:(NSButton *)aSender
{
	if (!asyncSocket)
	{		
		BOOL isSandbox = (self.buttonSandbox.state == NSOnState);
		
		NSString *host = isSandbox ? HOST_DEVELOPMENT : HOST_PRODUCTION;
		
		NSUInteger port = isSandbox ? PORT_DEVELOPMENT : PORT_PRODUCTION; 
		
		//	create socket
		
		asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
		
		if (![asyncSocket connectToHost:host onPort:port error:nil])
		{			
			[asyncSocket disconnect];
			
			[asyncSocket release]; asyncSocket = nil;
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
	if (asyncSocket)
	{
		[asyncSocket disconnect];
		
		[asyncSocket autorelease]; asyncSocket = nil;
	}
	
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
	
	[self loadCertificates:certificates];
	
	[comboBoxCertificate setStringValue:@""];
	
	[comboBoxCertificate reloadData];
	
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
								 
								 @"new",							KEY_NAME,
								 
								 @"enter notification id",			KEY_NOTIFICATION_ID,
								 
								 nil];
	
	[notificationIDs addObject:data];
	
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:(notificationIDs.count - 1)];

	[tableViewNotificationIDs reloadData];
		
	[tableViewNotificationIDs selectRowIndexes:indexes byExtendingSelection:NO];

	[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:KEY_NOTIFICATION_IDS];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickDeleteNotificationID
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickDeleteNotificationID:(NSButton *)aSender
{		
	[notificationIDs removeObjectsAtIndexes:[tableViewNotificationIDs selectedRowIndexes]];
	
	[tableViewNotificationIDs reloadData];

	[tableViewNotificationIDs selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];

	[[NSUserDefaults standardUserDefaults] setObject:notificationIDs forKey:KEY_NOTIFICATION_IDS];
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
//	method clickPost
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickPost:(NSButton *)aSender
{	
	for (NSDictionary *data in notificationIDs)
	{
		//	check if selected
		
		BOOL isSelected = [(NSNumber *)[data objectForKey:KEY_SELECTED] boolValue];
		
		if (!isSelected)
		{
			continue;
		}
								
		//	header data
		
		char headerData[37];
		
		headerData[0] = 0;		//	fixed
		
		headerData[1] = 0;		//	fixed
		
		headerData[2] = 32;		//	fixed
						
		//	notification id
	
		char *nextChar = &headerData[3];

		const char *hexChars = [[data objectForKey:KEY_NOTIFICATION_ID] UTF8String];
		
		const char *nextHex = hexChars;
			
		NSUInteger count = 0;
		
		//	TODO	check
		
		while (count < 32 && (count < strlen(hexChars)))
		{
			sscanf(nextHex, "%2x", (unsigned int *)nextChar);
			
			nextHex += 2;
			
			nextChar++;
			
			count++;
		}
		
		headerData[35] = 0;		//	fixed
		
		//	payload : alert
		
		NSString *plAlert = nil;
		
		if (buttonAlert.state == NSOnState)
		{
			NSString *string = textFieldAlert.stringValue;

			//	TODO	sanitize
			
			plAlert = [NSString stringWithFormat:JSON_ALERT_FORMAT, string];
		}

		//	payload : badge
		
		NSString *plBadge = nil;
		
		if (buttonBadge.state == NSOnState)
		{			
			plBadge = [NSString stringWithFormat:JSON_BADGE_FORMAT, textFieldBadge.stringValue.intValue];
		}

		//	payload : sound
		
		NSString *plSound = nil;
		
		if (buttonSound.state == NSOnState)
		{
			NSString *string = textFieldSound.stringValue;
			
			//	TODO	sanitize
			
			plSound = [NSString stringWithFormat:JSON_SOUND_FORMAT, string];
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
		
		//	payload
		
		NSString *payload = [NSString stringWithFormat:JSON_FORMAT, payloadAPS];
				
		const char *payloadChar = [payload cStringUsingEncoding:NSUTF8StringEncoding];
		
		//	TODO	check size
		
		headerData[36] = strlen(payloadChar);
				
		//	data
			
		NSMutableData *data = [[NSMutableData alloc] init];
		
		[data appendBytes:headerData length:sizeof(headerData)];

		[data appendBytes:payloadChar length:strlen(payloadChar)];
		
		[asyncSocket writeData:data withTimeout:10.0f tag:0];
				
		[data release];

	}
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickHelp
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickHelp:(NSButton *)aSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:HELP]];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket didConnectToHost
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
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
//	method onSocket willDisconnectWithError
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	//	TODO	error message
	
//	NSLog(@"Socket : Will disconnect with error");
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocketDidDisconnect
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	//	cleanup socket
	
	[asyncSocket setDelegate:nil];
	
	[asyncSocket disconnect];
	
	[asyncSocket autorelease]; asyncSocket = nil;
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------