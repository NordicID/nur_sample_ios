
#import "EULAViewController.h"
#import "ThemeManager.h"
#import "Log.h"

@interface EULAViewController ()

@end

@implementation EULAViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = [ThemeManager sharedInstance].theme.applicationTitle;

    // load the EULA from the bundle
    NSString* path = [[NSBundle mainBundle] pathForResource:@"EULA" ofType:@"txt"];
    NSError * error = nil;

    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];

    NSString* eula = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if ( error ) {
        logDebug( @"failed to read EULA from bundle: %@ %d", error.localizedDescription, exists );
    }

    self.eulaTextView.text = eula;
}


- (void) viewWillLayoutSubviews {
    [self.eulaTextView scrollRangeToVisible:NSMakeRange(0, 0)];
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
                                        logDebug(@"user declined" );
                                        [self showDeclinePrompt];
                                   }];

    [alert addAction:acceptButton];
    [alert addAction:declineButton];
    [self presentViewController:alert animated:YES completion:nil];
}


- (IBAction)decline:(UIButton *)sender {
    logDebug(@"user declined" );
    [self showDeclinePrompt];
}


- (void) showDeclinePrompt {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"License Agreemement", @"EULA declined popup title")
                                                                    message:NSLocalizedString(@"The license agreement must be accepted before the application can be used.", @"EULA declined popup text")
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok", @"EULA declined ok button in popup")
                                   style:UIAlertActionStyleDefault
                                   handler:nil];

    [alert addAction:okButton];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
