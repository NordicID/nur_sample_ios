
#import "UIViewController+Theme.h"
#import "ThemeManager.h"

@implementation UIViewController (Theme)

- (void) setupTheme {
    Theme * theme = [ThemeManager sharedInstance].theme;

    self.view.backgroundColor = theme.backgroundColor;
}

@end
