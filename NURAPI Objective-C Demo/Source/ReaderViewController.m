
#import "ReaderViewController.h"
#import "Tag.h"
#import "UIButton+BackgroundColor.h"

@interface ReaderViewController ()

@property (nonatomic, strong) NSMutableDictionary * foundTags;

@end

@implementation ReaderViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.scanButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.settingsButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.writeTagButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.infoButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
    [super viewWillAppear:animated];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.foundTags = [NSMutableDictionary dictionary];

    NSLog( @"reader: %@", self.reader );
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];
}


/*****************************************************************************************************************
 * Bluetooth delegate callbacks
 * The callbacks do not necessarily come on the main thread, so make sure everything that touches the UI is done on
 * the main thread only.
 **/
- (void) readerConnectionOk {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"connection ok" );
        self.scanButton.enabled = YES;
        self.scanButton.enabled = NO;
    });
}


- (void) readerConnectionFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"connection failed" );
        self.scanButton.enabled = NO;
        self.settingsButton.enabled = NO;
    });
}



@end
