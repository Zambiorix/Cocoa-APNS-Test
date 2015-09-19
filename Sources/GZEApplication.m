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

#define APNS_DEVELOPMENT                @"Apple Development Push Services"

#define APNS_DEVELOPMENT_IOS            @"Apple Development IOS Push Services"

#define APNS_PRODUCTION                 @"Apple Production Push Services"

#define APNS_PRODUCTION_IOS             @"Apple Production IOS Push Services"

#define HOST_GW_DEVELOPMENT             @"gateway.sandbox.push.apple.com"

#define HOST_GW_PRODUCTION              @"gateway.push.apple.com"

#define PORT_GW_DEVELOPMENT             2195

#define PORT_GW_PRODUCTION              2195

#define HOST_FB_DEVELOPMENT             @"feedback.sandbox.push.apple.com"

#define HOST_FB_PRODUCTION              @"feedback.push.apple.com"

#define PORT_FB_DEVELOPMENT             2196

#define PORT_FB_PRODUCTION              2196

#define DEFAULT_TIMEOUT                 10.0f

#define DEFAULT_FEEDBACK_INTERVAL       600.0f

#define DEFAULT_NOTIFICATION_ID         @"00000000-00000000-00000000-00000000-00000000-00000000-00000000-00000000"

#define DEFAULT_NOTIFICATION_NAME       @"?"

#define JSON_FORMAT                     @"{\"aps\":{%@}}"

#define JSON_FORMAT_CUSTOM_DATA         @"{\"aps\":{%@},%@}"

#define JSON_ALERT_FORMAT               @"\"alert\":\"%@\""

#define JSON_BADGE_FORMAT               @"\"badge\":%d"

#define JSON_SOUND_FORMAT               @"\"sound\":\"%@\""

#define JSON_CATEGORY_FORMAT            @"\"category\":\"%@\""

#define JSON_CONTENT_AVAILABLE          @"\"content-available\":1"

#define JSON_MAX_PAYLOAD                255

#define JSON_PAYLOAD_FORMAT             @"Payload size : %ld / %d"

#define FEEDBACK_PACKET_SIZE            38

//	--------------------------------------------------------------------------------------------------------------------
//	defines
//	--------------------------------------------------------------------------------------------------------------------

#define KEY_CERTIFICATE                 @"kCertificate"

#define KEY_SELECTED                    @"kSelected"

#define KEY_NAME                        @"kName"

#define KEY_NOTIFICATION_ID             @"kNotificationID"

#define KEY_SANDBOX                     @"kSandbox"

#define KEY_ALERT_ENABLED               @"kAlertEnabled"

#define KEY_ALERT                       @"kAlert"

#define KEY_BADGE_ENABLED               @"kBadgeEnabled"

#define KEY_BADGE                       @"kBadge"

#define KEY_SOUND_ENABLED               @"kSoundEnabled"

#define KEY_CATEGORY_ENABLED            @"kCategoryEnabled"

#define KEY_CONTENT_AVAILABLE_ENABLED	@"kContentAvailableEnabled"

#define KEY_SOUND                       @"kSound"

#define KEY_CATEGORY                    @"kCategory"

#define KEY_HELP_APNS                   @"kHelpAPNS"

#define KEY_CUSTOM_KEY                  @"kCustomKey"

#define KEY_CUSTOM_VALUE                @"kCustomValue"

#define KEY_CUSTOM_VALUES               @"kCustomValues"

#define KEY_CUSTOM_VALUES_ENABLED       @"kCustomValuesEnabled"


//	--------------------------------------------------------------------------------------------------------------------
//	class GZEApplication
//	--------------------------------------------------------------------------------------------------------------------

@interface GZEApplication (Private)

- (NSString *)buildPayloadWithAlert:(NSString *)aAlert withBadge:(NSString *)aBadge withSound:(NSString *)aSound withCategory:(NSString *)aCategroy;

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

@synthesize buttonCategory;

@synthesize textFieldCategory;

@synthesize buttonContentAvailable;

@synthesize textViewOutput;

@synthesize buttonSendNotification;

@synthesize textFieldFooter;

@synthesize tableViewCustomKeys;

@synthesize buttonAddCustomKey;

@synthesize buttonCustomKeys;

@synthesize buttonDeleteCustomKey;

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
							
							if (!includeCertificate)
							{
								includeCertificate = [(NSString *)commonName hasPrefix:APNS_DEVELOPMENT_IOS];
							}
						}
						else
						{
							includeCertificate = [(NSString *)commonName hasPrefix:APNS_PRODUCTION];

							if (!includeCertificate)
							{
								includeCertificate = [(NSString *)commonName hasPrefix:APNS_PRODUCTION_IOS];
							}
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
	BOOL hasNoGWSocket = (socketGateway == nil);

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
	
	[buttonConnect setEnabled:hasNoGWSocket && hasCertificate];

	[buttonDisconnect setEnabled:!hasNoGWSocket];
			
	[comboBoxCertificate setEnabled:hasNoGWSocket];

	[buttonSandbox setEnabled:hasNoGWSocket];

	[tableViewNotificationIDs setEnabled:hasNotificationIDs];
	
	[buttonAddNotificationID setEnabled:hasNotificationIDs];
	
	[buttonDeleteNotificationID setEnabled:hasNotificationIDs && hasNotificationIDsSelected];
    
    BOOL customKeysEnabled = buttonCustomKeys.state == NSOnState;
    
    [buttonAddCustomKey setEnabled:customKeysEnabled];
    
    [buttonDeleteCustomKey setEnabled:customKeysEnabled];
    
    [tableViewCustomKeys setEnabled:customKeysEnabled];
	
	[textFieldAlert setEnabled:(buttonAlert.state == NSOnState)];

	[textFieldBadge setEnabled:(buttonBadge.state == NSOnState)];

	[textFieldSound setEnabled:(buttonSound.state == NSOnState)];
	
	[textFieldCategory setEnabled:(buttonCategory.state == NSOnState)];

	[buttonSendNotification setEnabled:!hasNoGWSocket && hasNotificationIDsToSend];

	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue
						 
										  withBadge:textFieldBadge.stringValue
						 
										  withSound:textFieldSound.stringValue
						 
									   withCategory:textFieldCategory.stringValue];
		
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
		
	textFieldFooter.stringValue = [NSString stringWithFormat:JSON_PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD];
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
    
    // loading default : custom values
    
    customValues = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_CUSTOM_VALUES] mutableCopy];
    
    if (customValues == nil)
    {
        customValues = [[NSMutableArray alloc]init];
    }
	
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
	
	// loading defaults : category
	
	BOOL isCategory = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_CATEGORY_ENABLED];
	
	buttonCategory.state = isCategory ? NSOnState : NSOffState;
	
//	textFieldCategory.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_CATEGORY];
	
    //	loading defaults : content available
    
	BOOL isContentAvailable = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_CONTENT_AVAILABLE_ENABLED];
	
	buttonContentAvailable.state =  isContentAvailable ? NSOnState : NSOffState;
	
	//	register drag types
	
	[tableViewNotificationIDs registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];
	
	//	initialize output attributes
	
	NSFont *font = [NSFont fontWithName:@"Menlo" size:13.0f];
	
	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	
	style.lineBreakMode = NSLineBreakByCharWrapping;
	
	textViewOutputAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								
								font, NSFontAttributeName,
								
								style, NSParagraphStyleAttributeName,
								
								nil];	
	
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
	//	cleanup output attributes
	
	[textViewOutputAttributes release]; textViewOutputAttributes = nil;
	
	//	cleanup socket gateway
	
	[socketGateway setDelegate:nil];
	
	[socketGateway disconnect];
	
	[socketGateway release]; socketGateway = nil;
		
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
	
	NSInteger index = comboBoxCertificate.indexOfSelectedItem;

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
	
    return [NSString stringWithFormat:@"%@ (%@)", certifcate.key, certifcate.name];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method numberOfRowsInTableView
//	--------------------------------------------------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    if (tableView == tableViewCustomKeys)
    {
        return customValues ? customValues.count : 0;
    }
    else
    {
        return notificationIDs ? notificationIDs.count : 0;
    }
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableView objectValueForTableColumn
//	--------------------------------------------------------------------------------------------------------------------

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row 
{
    if (tableView == tableViewCustomKeys)
    {
        return [[customValues objectAtIndex:row] objectForKey:[column identifier]];
    }
    else
    {
        return [[notificationIDs objectAtIndex:row] objectForKey:[column identifier]];
    }
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableView setObjectValue
//	--------------------------------------------------------------------------------------------------------------------

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(NSInteger)row 
{
 	if (tableView == tableViewCustomKeys) {
    
        [[customValues objectAtIndex:row] setObject:[NSString stringWithFormat:@"%@",value] forKey:[column identifier]];
        
        [[NSUserDefaults standardUserDefaults] setObject:customValues forKey:KEY_CUSTOM_VALUES];
        
    }
    else
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
        
    }
    
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

- (NSDragOperation)tableView:(NSTableView*)tableView
				
				validateDrop:(id<NSDraggingInfo>)info 
				 
				 proposedRow:(NSInteger)row 
	   
	   proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (tableView == tableViewCustomKeys)
    {
        return NSDragOperationNone;
    }
    else
    {
        return NSDragOperationEvery;
    }
}

//	--------------------------------------------------------------------------------------------------------------------
//	method tableView acceptDrop validateDrop proposedRow proposedDropOperation
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)tableView:(NSTableView *)tableView
	   
	   acceptDrop:(id<NSDraggingInfo>)info

			  row:(NSInteger)row 
	
	dropOperation:(NSTableViewDropOperation)operation
{
    if (tableView == tableViewCustomKeys)
    {
        return NO;
    }
    
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
//	method buildNotificationID onLocation
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)buildNotificationIDString:(NSArray *)aNotificationID
{	
	return [NSString stringWithFormat:@"%08x %08x %08x %08x %08x %08x %08x %08x", 

			[[aNotificationID objectAtIndex:0] intValue],

			[[aNotificationID objectAtIndex:1] intValue],
			
			[[aNotificationID objectAtIndex:2] intValue],
			
			[[aNotificationID objectAtIndex:3] intValue],
			
			[[aNotificationID objectAtIndex:4] intValue],
			
			[[aNotificationID objectAtIndex:5] intValue],
			
			[[aNotificationID objectAtIndex:6] intValue],
			
			[[aNotificationID objectAtIndex:7] intValue]
			
			];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method JSONString
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)JSONString:(NSString *)aString 
{
	NSMutableString *s = [NSMutableString stringWithString:aString];
	
	NSRange r = NSMakeRange(0, [s length]);
	
	[s replaceOccurrencesOfString:@"\""	withString:@"\\\""	options:NSCaseInsensitiveSearch range:r];
		
	[s replaceOccurrencesOfString:@"\n"	withString:@"\\n"	options:NSCaseInsensitiveSearch range:r];
	
	[s replaceOccurrencesOfString:@"\b"	withString:@"\\b"	options:NSCaseInsensitiveSearch range:r];
	
	[s replaceOccurrencesOfString:@"\f"	withString:@"\\f"	options:NSCaseInsensitiveSearch range:r];
	
	[s replaceOccurrencesOfString:@"\r"	withString:@"\\r"	options:NSCaseInsensitiveSearch range:r];
	
	[s replaceOccurrencesOfString:@"\t"	withString:@"\\t"	options:NSCaseInsensitiveSearch range:r];
	
	[s replaceOccurrencesOfString:@"/"	withString:@"\\/"	options:NSCaseInsensitiveSearch range:r];

	return [NSString stringWithString:s];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method buildPayloadWithAlert withBadge withSound withCategory
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)buildPayloadWithAlert:(NSString *)aAlert withBadge:(NSString *)aBadge withSound:(NSString *)aSound withCategory:(NSString *)aCategory
{	
	//	payload : alert
	
    NSMutableArray * payloadApsArray = [NSMutableArray array];
    	
	if (buttonAlert.state == NSOnState)
	{
		[payloadApsArray addObject:[NSString stringWithFormat:JSON_ALERT_FORMAT,[self JSONString:aAlert]]];
	}
	
	//	payload : badge
	
	if (buttonBadge.state == NSOnState)
	{			
		[payloadApsArray addObject:[NSString stringWithFormat:JSON_BADGE_FORMAT, aBadge.intValue]];
	}
	
	//	payload : sound
		
	if (buttonSound.state == NSOnState)
	{		
		[payloadApsArray addObject:[NSString stringWithFormat:JSON_SOUND_FORMAT, [self JSONString:aSound]]];
	}
	
	//	payload : category
	
	if (buttonCategory.state == NSOnState)
    {
		[payloadApsArray addObject:[NSString stringWithFormat:JSON_CATEGORY_FORMAT, [self JSONString:aCategory]]];
	}
    
    // payload : content available
    
    if (buttonContentAvailable.state == NSOnState)
    {
        [payloadApsArray addObject:JSON_CONTENT_AVAILABLE];
    }
	
	//	payload
	
	NSString *payloadAPS = [payloadApsArray componentsJoinedByString:@","];
    
    NSString *payload = nil;
    
    if (buttonCustomKeys.state == NSOnState && customValues.count > 0)
    {
        NSMutableArray * payloadCustomDataArray = [NSMutableArray array];
        
        for (NSDictionary * d in customValues)
        {
            NSString * customKey = [self JSONString:[d objectForKey:KEY_CUSTOM_KEY]];
            
            NSString * customValue = [self JSONString:[d objectForKey:KEY_CUSTOM_VALUE]];
            
            NSString * customDataRow = [NSString stringWithFormat:@"\"%@\":\"%@\"",customKey,customValue];
            
            [payloadCustomDataArray addObject:customDataRow];
        }
        
        payload = [NSString stringWithFormat:JSON_FORMAT_CUSTOM_DATA, payloadAPS, [payloadCustomDataArray componentsJoinedByString:@","]];
    }
    else
    {
        payload = [NSString stringWithFormat:JSON_FORMAT, payloadAPS];
    }

	return payload;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method buildFormattedPayload
//	--------------------------------------------------------------------------------------------------------------------

- (NSAttributedString *)buildFormattedPayload:(NSString *)aPayload
{			
	return [[[NSAttributedString alloc] initWithString:aPayload attributes:textViewOutputAttributes] autorelease];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method buildPayload
//	--------------------------------------------------------------------------------------------------------------------

- (NSUInteger)buildPayload:(NSMutableData *)aData
{	
	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue 
						 
										  withBadge:textFieldBadge.stringValue 
						 
										  withSound:textFieldSound.stringValue
						 
									   withCategory:textFieldCategory.stringValue];
	
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
	
	if (control == textFieldCategory)
	{
		[[NSUserDefaults standardUserDefaults] setObject:object forKey:KEY_CATEGORY];
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
										  
										  withSound:textFieldSound.stringValue
						 
									   withCategory:textFieldCategory.stringValue];

	if (payload.length > JSON_MAX_PAYLOAD)
	{		
		return NO;
	}
	
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
	
	textFieldFooter.stringValue = [NSString stringWithFormat:JSON_PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD];

	return YES;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method formatBadgeCheck forString
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)formatBadgeCheck:(GZEFormatBadge *)aBadge forString:(NSString *)aString
{
	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue 
						 
										  withBadge:aString 
						 
										  withSound:textFieldSound.stringValue
						 
									   withCategory:textFieldCategory.stringValue];

	if (payload.length > JSON_MAX_PAYLOAD)
	{		
		return NO;
	}
	
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
	
	textFieldFooter.stringValue = [NSString stringWithFormat:JSON_PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD];
	
	return YES;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method formatSoundCheck forString
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)formatSoundCheck:(GZEFormatSound *)aSound forString:(NSString *)aString
{
	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue
						 
										  withBadge:textFieldBadge.stringValue 
						 
										  withSound:aString
						 
									   withCategory:textFieldCategory.stringValue];
	
	if (payload.length > JSON_MAX_PAYLOAD)
	{		
		return NO;
	}
	
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
	
	textFieldFooter.stringValue = [NSString stringWithFormat:JSON_PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD];
	
	return YES;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method formatCategoryCheck forString
//	--------------------------------------------------------------------------------------------------------------------

- (BOOL)formatCategoryCheck:(GZEFormatCategory *)aCategory forString:(NSString *)aString
{
	NSString *payload = [self buildPayloadWithAlert:textFieldAlert.stringValue 
						 
										  withBadge:textFieldBadge.stringValue 
						 
										  withSound:aString
						 
									   withCategory:textFieldCategory.stringValue];
	
	if (payload.length > JSON_MAX_PAYLOAD)
	{		
		return NO;
	}
	
	[[textViewOutput textStorage] setAttributedString:[self buildFormattedPayload:payload]];
	
	textFieldFooter.stringValue = [NSString stringWithFormat:JSON_PAYLOAD_FORMAT, payload.length, JSON_MAX_PAYLOAD];
	
	return YES;
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
//	method clickAddCustomKey
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickAddCustomKey:(NSButton *)aSender
{
	NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 
								 @"key",		KEY_CUSTOM_KEY,
								 
								 @"value",		KEY_CUSTOM_VALUE,
								 
								 nil];
	
	[customValues addObject:data];
	
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:(customValues.count - 1)];
    
	[tableViewCustomKeys reloadData];
    
	[tableViewCustomKeys selectRowIndexes:indexes byExtendingSelection:NO];
    
	[[NSUserDefaults standardUserDefaults] setObject:customValues forKey:KEY_CUSTOM_VALUES];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickDeleteCustomKey
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickDeleteCustomKey:(NSButton *)aSender
{
	[customValues removeObjectsAtIndexes:[tableViewCustomKeys selectedRowIndexes]];
	
	[tableViewCustomKeys reloadData];
    
	[tableViewCustomKeys selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    
	[[NSUserDefaults standardUserDefaults] setObject:customValues forKey:KEY_CUSTOM_VALUES];
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
//	method clickCategory
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickCategory:(NSButton *)sender
{
	BOOL isEnabled = (buttonCategory.state == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isEnabled] forKey:KEY_CATEGORY_ENABLED];
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickContentAvailable
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickContentAvailable:(NSButton *)aSender
{
	BOOL isEnabled = (buttonContentAvailable.state == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isEnabled] forKey:KEY_CONTENT_AVAILABLE_ENABLED];
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method clickCustomKeys
//	--------------------------------------------------------------------------------------------------------------------

- (IBAction)clickCustomKeys:(NSButton *)aSender
{
	BOOL isEnabled = (buttonCustomKeys.state == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isEnabled] forKey:KEY_CUSTOM_VALUES_ENABLED];
	
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

		NSLog(@"Socket GW : Push to : %@", [self buildNotificationIDString:[data objectForKey:KEY_NOTIFICATION_ID]]);
		
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
//	method hexStringFromBytes
//	--------------------------------------------------------------------------------------------------------------------

- (NSString *)hexStringFromBytes:(NSData *)aData
{
	NSUInteger byteCount = [aData length];
	
	if (byteCount == 0)
	{
		return @"";
	}
	
	static const char hexDigits[] = "0123456789abcdef";
	
	const unsigned char *byteBuffer = [aData bytes];
	
	char *stringBuffer = (char *)malloc(byteCount * 2 + 1);
	
	char *hexChar = stringBuffer;
	
	while (byteCount-- > 0) 
	{
		const unsigned char c = *byteBuffer++;
		
		*hexChar++ = hexDigits[(c >> 4) & 0xF];
		
		*hexChar++ = hexDigits[(c >> 0) & 0xF];
	}
	
	*hexChar = 0;
	
	NSString *hexBytes = [NSString stringWithUTF8String:stringBuffer];
	
	free(stringBuffer);
	
	return hexBytes;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket didConnectToHost
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)aSocket didConnectToHost:(NSString *)aHost port:(UInt16)aPort
{	
	if (aSocket == socketGateway)
	{
		//	connection established
		
		NSLog(@"Socket GW : Connected : %@ : %d", aHost, aPort);
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

	[aSocket startTLS:settings];
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocketDidSecure
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocketDidSecure:(AsyncSocket *)aSocket
{
	if (aSocket == socketGateway)
	{
		//	start reading
		
		[socketGateway readDataWithTimeout:DEFAULT_TIMEOUT tag:0];
		
		//	connection established

		NSLog(@"Socket GW : Secured");
	}
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket didReadData
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)aSocket didReadData:(NSData *)aData withTag:(long)aTag
{
	if (aSocket == socketGateway)
	{
		NSLog(@"Socket GW : Read");

		[socketGateway readDataWithTimeout:DEFAULT_TIMEOUT tag:0];		
	}	
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket shouldTimeoutReadWithTag elapsed bytesDone
//	--------------------------------------------------------------------------------------------------------------------

- (NSTimeInterval)onSocket:(AsyncSocket *)aSocket

  shouldTimeoutReadWithTag:(long)aTag

				   elapsed:(NSTimeInterval)aElapsed

				 bytesDone:(CFIndex)aLength
{
	return DEFAULT_TIMEOUT;
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocket willDisconnectWithError
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocket:(AsyncSocket *)aSocket willDisconnectWithError:(NSError *)aError
{
	if (aSocket == socketGateway)
	{
		NSLog(@"Socket GW : Error : %@", aError);
	}	
}

//	--------------------------------------------------------------------------------------------------------------------
//	method onSocketDidDisconnect
//	--------------------------------------------------------------------------------------------------------------------

- (void)onSocketDidDisconnect:(AsyncSocket *)aSocket
{
	//	cleanup socket gateway
	
	if (aSocket == socketGateway)
	{				
		//	cleanup socket gateway
		
		[socketGateway setDelegate:nil];
		
		[socketGateway disconnect];
		
		[socketGateway release]; socketGateway = nil;
	
		//	connection terminated
		
		NSLog(@"Socket GW : Terminated");
	}
	
	//	update status
	
	[self updateStatus];
}

//	--------------------------------------------------------------------------------------------------------------------
//	done
//	--------------------------------------------------------------------------------------------------------------------

@end

//	--------------------------------------------------------------------------------------------------------------------