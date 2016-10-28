
#import "LocateTagViewController.h"

@interface LocateTagViewController ()

@end

@implementation LocateTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void) viewWillAppear:(BOOL)animated {
    self.tagLabel.text = self.tag.hex;
    [super viewWillAppear:animated];
}

@end
