#import "UtilsPlugin.h"
#import <sys/sysctl.h>

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

- (void)getDevice:(NSDictionary *)jsonObject {
    NSString *m_platform = 0;
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size + 1);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    machine[size] = '\0';
    m_platform = [NSString stringWithUTF8String:machine];
    free(machine);

    [[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"deviceInfo",@"name",
                                                  m_platform,@"device",
                                                  @"ios",@"type",
                                                  @"ios",@"store",
                                                  [[UIDevice currentDevice] systemVersion],@"os",
                                                  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],@"versionNumber",
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
    NSURL *shareURL = [NSURL URLWithString:url];
    NSMutableArray *sharingItems = [NSMutableArray new];
    [sharingItems addObject:shareText];
    [sharingItems addObject:shareURL];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIViewController *topView = window.rootViewController;
    [topView presentViewController:activityController animated:YES completion:nil];
}

@end