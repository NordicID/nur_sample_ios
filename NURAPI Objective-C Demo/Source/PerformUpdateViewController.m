
#import "PerformUpdateViewController.h"

@interface PerformUpdateViewController ()

@end

@implementation PerformUpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void) viewWillAppear:(BOOL)animated {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    self.nameLabel.text = [NSString stringWithFormat:@"Name: %@", self.firmware.name];
    self.versionLabel.text = [NSString stringWithFormat:@"Version: %@", self.firmware.version];
    self.buildTimeLabel.text = [NSString stringWithFormat:@"Build time: %@", [dateFormatter stringFromDate:self.firmware.buildTime]];
}


- (IBAction)performUpdate:(UIButton *)sender {
    NSLog( @"updating to firmware %@", self.firmware.name );
    
    // show in an alert view
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Oops"
                                                                    message:@"Not yet implemented"
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // nothing special to do right now
                               }];


    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
