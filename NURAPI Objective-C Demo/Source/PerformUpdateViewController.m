
#import "PerformUpdateViewController.h"

@interface PerformUpdateViewController ()

@end

@implementation PerformUpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (IBAction)performUpdate:(UIButton *)sender {
    NSLog( @"updating to firmware %@", self.firmware.name );
}

@end
