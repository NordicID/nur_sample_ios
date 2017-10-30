
#import <UIKit/UIKit.h>

/**
 * Defines a theme that can set up a target specific visual appearance. Each target must have an
 * implementation that implements all methods.
 **/
@interface ViewControllerManager : NSObject

+ (UIWindow *) setupRootViewController;

@end

