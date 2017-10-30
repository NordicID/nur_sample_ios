
#import "ViewControllerManager.h"

@implementation ViewControllerManager

+ (UIWindow *) setupRootViewController {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // is the EULA accepted?
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if ( [defaults objectForKey:@"eulaAccepted"] != nil ) {
        // EULA accepted instantiate the main navigation view controller
        UINavigationController * nc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainNavigationController"];
        [UIApplication sharedApplication].keyWindow.rootViewController = nc;
        window.rootViewController = nc;
    }
    else {
        // EULA not accepted instantiate the EULA view controller
        UIViewController * vc = [[UIStoryboard storyboardWithName:@"EULA" bundle:nil] instantiateViewControllerWithIdentifier:@"EULAViewController"];
        [UIApplication sharedApplication].keyWindow.rootViewController = vc;
        window.rootViewController = vc;
    }

    return window;
}

@end

