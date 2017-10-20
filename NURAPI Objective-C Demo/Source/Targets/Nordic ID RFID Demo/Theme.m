
#import "../../Theme.h"

@implementation Theme

+ (void) setupTheme {
    // navigation bar
    [UINavigationBar appearance].barStyle = UIBarStyleBlack;
    [UINavigationBar appearance].translucent = NO;
    [UINavigationBar appearance].barTintColor = [UIColor redColor];
    [UINavigationBar appearance].tintColor = [UIColor greenColor];
    [UINavigationBar appearance].titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor blueColor] };

    // button
    [UIButton appearance].backgroundColor = [UIColor redColor];
    [[UIButton appearance] setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
}

@end
