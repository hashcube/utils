#import "UtilsPlugin.h"

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
    [[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"deviceInfo",@"name",
                                                  [[UIDevice currentDevice] platformString],@"device",
                                                  @"ios",@"type",
                                                  [[UIDevice currentDevice] systemVersion],@"os",
                                                  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],@"versionNumber",
                                                  nil]];
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