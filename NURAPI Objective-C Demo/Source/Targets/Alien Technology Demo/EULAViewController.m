
#import "EULAViewController.h"

@interface EULAViewController ()

@end

@implementation EULAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (IBAction)accept:(UIButton *)sender {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm", @"EULA popup title")
                                                                    message:NSLocalizedString(@"Do you accept the end user license agreement?", @"EULA popup text")
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* acceptButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Accept", @"EULA accept in popup")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       // user confirmed, proceed!
                                       NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                                       [defaults setBool:YES forKey:@"eulaAccepted"];
                                       [defaults synchronize];

                                       // instantiate the view controller
                                       UINavigationController * nc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainNavigationController"];
                                       [UIApplication sharedApplication].keyWindow.rootViewController = nc;
                                   }];

    UIAlertAction* declineButton = [UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Decline", @"EULA decline in popup")
                                    style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction * action) {
                                        NSLog(@"user declined" );
                                    }];

    [alert addAction:acceptButton];
    [alert addAction:declineButton];

    // when the dialog is up, then start downloading
    [self presentViewController:alert animated:YES completion:nil];
}


- (IBAction)decline:(UIButton *)sender {
    NSLog(@"user declined" );
}

@end
