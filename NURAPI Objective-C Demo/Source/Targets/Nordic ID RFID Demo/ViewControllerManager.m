
#import "ViewControllerManager.h"

@implementation ViewControllerManager

+ (UIWindow *) setupRootViewController {
    // just instantiate the normal main navigation controller, no special setup
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UINavigationController * nc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainNavigationController"];
    [UIApplication sharedApplication].keyWindow.rootViewController = nc;
    window.rootViewController = nc;
    return window;
}

@end

