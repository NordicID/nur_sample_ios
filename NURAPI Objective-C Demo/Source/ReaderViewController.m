
#import "ReaderViewController.h"
#import "Tag.h"

@interface ReaderViewController ()

@property (nonatomic, strong) NSMutableDictionary * foundTags;

@end

@implementation ReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.foundTags = [NSMutableDictionary dictionary];

    NSLog( @"reader: %@", self.reader );

    self.connectedLabel.text = self.reader.identifier.UUIDString;
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
        self.settingsButton.enabled = YES;
    });
}


- (void) readerConnectionFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"connection failed" );
        self.scanButton.enabled = NO;
        self.settingsButton.enabled = NO;
        self.writeTagButton.enabled = NO;
        self.infoButton.enabled = NO;
        self.readBarcodeButton.enabled = NO;
    });
}



@end
