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

- (void)shareText:(NSString *)string andImage:(UIImage *)image
{
    NSMutableArray *sharingItems = [NSMutableArray new];

    if (string) {
        [sharingItems addObject:string];
    }
    if (image) {
        [sharingItems addObject:image];
    }

    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

@end

