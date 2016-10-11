#import "UtilsPlugin.h"
#import <sys/sysctl.h>
#import <AdSupport/ASIdentifierManager.h>

@implementation UtilsPlugin

// The plugin must call super dealloc.
- (void) dealloc {
	[super dealloc];
}

// The plugin must call super init.
- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}
	return self;
}

// Called from native-ios for 3D touch action
- (void) performActionForShortcutItem:(UIApplicationShortcutItem *) shortcutItem {
    //Attempt to send to Application.js
    @try {
        [[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
            @"performActionForShortcutItem", @"name",
            shortcutItem.type, @"val",
            nil]];
    }
    @catch (NSException *exception) {
        NSLog(@"{3DTouch} Failure to get: %@", exception);
    }
}

- (void) updateShortcutItems: (NSDictionary *)jsonObject {
    NSString *appGroup = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"WidgetGroup"];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroup];

    NSMutableArray *shortcutItem = [[NSMutableArray alloc] init];

    for (id key in jsonObject) {
        NSDictionary *dict = [jsonObject objectForKey:key];
        UIApplicationShortcutItem *item = [[UIApplicationShortcutItem alloc]initWithType:key
			localizedTitle: [dict objectForKey:@"title"]
			localizedSubtitle: nil
			icon: [UIApplicationShortcutIcon
				iconWithType:[self UIApplicationShortcutIconTypeFromString:[dict objectForKey:@"icon"]]]
			userInfo: nil];
		// Push item to array
		[shortcutItem addObject:item];

        [sharedDefaults setObject:[dict objectForKey:@"title"] forKey:key];
    }
    [UIApplication sharedApplication].shortcutItems = shortcutItem;
    [sharedDefaults synchronize];
    NSLog(@"{3DTouch} => List Updated");
}

- (UIApplicationShortcutIconType) UIApplicationShortcutIconTypeFromString:(NSString*)str {
    // iOS 9.0 icons:
    if ([str isEqualToString:@"compose"])       return UIApplicationShortcutIconTypeCompose;
    else if ([str isEqualToString:@"play"])          return UIApplicationShortcutIconTypePlay;
    else if ([str isEqualToString:@"pause"])         return UIApplicationShortcutIconTypePause;
    else if ([str isEqualToString:@"add"])           return UIApplicationShortcutIconTypeAdd;
    else if ([str isEqualToString:@"location"])      return UIApplicationShortcutIconTypeLocation;
    else if ([str isEqualToString:@"search"])        return UIApplicationShortcutIconTypeSearch;
    else if ([str isEqualToString:@"share"])         return UIApplicationShortcutIconTypeShare;

    // iOS 9.1 icons:
#ifdef __IPHONE_9_1
    else if ([str isEqualToString:@"prohibit"])      return UIApplicationShortcutIconTypeProhibit;
    else if ([str isEqualToString:@"contact"])       return UIApplicationShortcutIconTypeContact;
    else if ([str isEqualToString:@"home"])          return UIApplicationShortcutIconTypeHome;
    else if ([str isEqualToString:@"marklocation"])  return UIApplicationShortcutIconTypeMarkLocation;
    else if ([str isEqualToString:@"favorite"])      return UIApplicationShortcutIconTypeFavorite;
    else if ([str isEqualToString:@"love"])          return UIApplicationShortcutIconTypeLove;
    else if ([str isEqualToString:@"cloud"])         return UIApplicationShortcutIconTypeCloud;
    else if ([str isEqualToString:@"invitation"])    return UIApplicationShortcutIconTypeInvitation;
    else if ([str isEqualToString:@"confirmation"])  return UIApplicationShortcutIconTypeConfirmation;
    else if ([str isEqualToString:@"mail"])          return UIApplicationShortcutIconTypeMail;
    else if ([str isEqualToString:@"message"])       return UIApplicationShortcutIconTypeMessage;
    else if ([str isEqualToString:@"date"])          return UIApplicationShortcutIconTypeDate;
    else if ([str isEqualToString:@"time"])          return UIApplicationShortcutIconTypeTime;
    else if ([str isEqualToString:@"capturephoto"])  return UIApplicationShortcutIconTypeCapturePhoto;
    else if ([str isEqualToString:@"capturevideo"])  return UIApplicationShortcutIconTypeCaptureVideo;
    else if ([str isEqualToString:@"task"])          return UIApplicationShortcutIconTypeTask;
    else if ([str isEqualToString:@"taskcompleted"]) return UIApplicationShortcutIconTypeTaskCompleted;
    else if ([str isEqualToString:@"alarm"])         return UIApplicationShortcutIconTypeAlarm;
    else if ([str isEqualToString:@"bookmark"])      return UIApplicationShortcutIconTypeBookmark;
    else if ([str isEqualToString:@"shuffle"])       return UIApplicationShortcutIconTypeShuffle;
    else if ([str isEqualToString:@"audio"])         return UIApplicationShortcutIconTypeAudio;
    else if ([str isEqualToString:@"update"])        return UIApplicationShortcutIconTypeUpdate;
#endif

    else {
        NSLog(@"Invalid iconType passed to the 3D Touch plugin. So not adding one.");
        //return 0;
    }
}


- (void)getDeviceInfo:(NSDictionary *)jsonObject {
	NSString *m_platform = 0;
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = (char*)malloc(size + 1);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	machine[size] = '\0';
	m_platform = [NSString stringWithUTF8String:machine];
	free(machine);
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSURL* urlToDocumentsFolder = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
									inDomains:NSUserDomainMask] lastObject];
	__autoreleasing NSError *error;
	NSDate *installDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:urlToDocumentsFolder.path
										error:&error] objectForKey:NSFileCreationDate];
	NSString * version =  [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"];

	[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
		@"deviceInfo",@"name",
		m_platform,@"device",
		@"ios",@"type",
		[NSNumber numberWithDouble:[installDate timeIntervalSince1970] * 1000],@"installDate",
		@"ios",@"store",
		language,@"language",
		[[UIDevice currentDevice] systemVersion],@"os",
		version,@"versionNumber",
		nil]];
}

- (void)logIt: (NSDictionary *)jsonObject{
	NSString *message = [NSString stringWithFormat:@""];

	for (id key in jsonObject) {
		id o = [jsonObject objectForKey:key];
		if([key isEqual:@"message"]){
			message = o;
			continue;
		}
	}

	NSLog(@"{utils-native} LOGIT = %@", message);
}

- (void)shareText:(NSDictionary *)jsonObject {
	NSString *shareText =  [NSString stringWithFormat:@""];
	NSString *url = [NSString stringWithFormat:@"http://www.sudokuquest.com"];

	for (id key in jsonObject) {
		id o = [jsonObject objectForKey:key];
		if([key isEqual:@"message"]){
			shareText = o;
			continue;
		}
		if([key isEqual:@"url"]){
			url = o;
			continue;
		}
	}
	shareText = [shareText stringByAppendingString:@" : #sudoku #sudokuquest "];
	NSURL *shareURL = [NSURL URLWithString:url];
	NSMutableArray *sharingItems = [NSMutableArray new];
	[sharingItems addObject:shareText];
	[sharingItems addObject:shareURL];

	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	UIViewController *topView = window.rootViewController;
	UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];

	[activityController setExcludedActivityTypes:
		@[UIActivityTypeAssignToContact,
		UIActivityTypeCopyToPasteboard,
		UIActivityTypePrint,
		UIActivityTypeSaveToCameraRoll,
		UIActivityTypeAddToReadingList,
		UIActivityTypePostToWeibo]];

	if ([activityController respondsToSelector:@selector(popoverPresentationController)] ) {
		// iOS8
		activityController.popoverPresentationController.sourceView = topView.view;
	}
	[topView presentViewController:activityController animated:YES completion:nil];
	// adding callback, to check where the content is shared
	[activityController setCompletionHandler:^(NSString *act, BOOL done)
	{
		NSString *sharedApp = nil;
		if ( [act isEqualToString:UIActivityTypeMail])				sharedApp = @"Mail";
		if ( [act isEqualToString:UIActivityTypePostToTwitter])		sharedApp = @"Twitter";
		if ( [act isEqualToString:UIActivityTypePostToFacebook])	sharedApp = @"Facebook";
		if ( [act isEqualToString:UIActivityTypeMessage])			sharedApp = @"SMS";
		if ( ~done)                                                 sharedApp = @"cancelled";

        [[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
                                              @"sharedWithApp",@"name",
                                              sharedApp,@"sharedApp",
                                              nil]];
	}];
}

/* Code adapted from
 * http://resources.infosecinstitute.com/ios-application-security-part-23-jailbreak-detection-evasion/
 */
- (void)isJailBroken:(NSDictionary *)jsonObject {

	//By default device is not jailbroken
	BOOL jailBroken = NO;
#if !(TARGET_IPHONE_SIMULATOR)
	if ([[NSFileManager defaultManager]
			fileExistsAtPath:@"/Applications/Cydia.app"]) {
		jailBroken = YES;
	} else if([[NSFileManager defaultManager]
			fileExistsAtPath:@"/Library/MobileSubstrate/MobileSubstrate.dylib"]) {
		jailBroken = YES;
	} else if([[NSFileManager defaultManager]
			fileExistsAtPath:@"/bin/bash"]) {
		jailBroken = YES;
	} else if([[NSFileManager defaultManager]
			fileExistsAtPath:@"/usr/sbin/sshd"]) {
		jailBroken = YES;
	} else if([[NSFileManager defaultManager]
			fileExistsAtPath:@"/etc/apt"]) {
		jailBroken = YES;
	}

	NSError *error;
	NSString *stringToBeWritten = @"This is a test.";
	[stringToBeWritten writeToFile:@"/private/jailbreak.txt" atomically:YES
		encoding:NSUTF8StringEncoding error:&error];
	if(error == nil) {
		//Device is jailbroken
		jailBroken = YES;
	} else {
		[[NSFileManager defaultManager] removeItemAtPath:@"/private/jailbreak.txt" error:nil];
	}

	if([[UIApplication sharedApplication]
			canOpenURL:[NSURL URLWithString:@"cydia://package/com.example.package"]]) {
		//Device is jailbroken
		jailBroken = YES;
	}
#endif

	NSString *ret = (jailBroken)? @"true": @"false";
	[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
		@"utilsJailBroken",@"name",
		ret,@"jb",
		nil]];
}

- (void)getAdvertisingId:(NSDictionary *)jsonObject {
	NSString *limit_tracking = @"1";
	NSString *id = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];

	if([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
		limit_tracking = @"0";
	}
	[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
		@"utilsAdvertisingId",@"name",
		id,@"id",
		limit_tracking, @"limit_tracking",
		nil]];
}

- (NSString *)valueForKey:(NSString *)key
           fromQueryItems:(NSArray *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems
                                  filteredArrayUsingPredicate:predicate]
                                 firstObject];
    return queryItem.value;
}

- (void) handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url
                                                resolvingAgainstBaseURL:NO];
    NSArray *queryItems = urlComponents.queryItems;
    NSString *widgetAction = [self valueForKey:@"widgetAction"
                          fromQueryItems:queryItems];

    if([widgetAction length] != 0) {
        [[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
            @"performActionForShortcutItem", @"name",
            widgetAction, @"val",
            nil]];
    }
}
@end
