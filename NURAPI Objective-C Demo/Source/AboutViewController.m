
#import <NurAPIBluetooth/Bluetooth.h>

#import "AboutViewController.h"


@interface AboutViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end


@interface AboutViewController ()

@end

@implementation AboutViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"About", nil);

    // set up links
    self.gitHubLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.gitHubLabel.delegate = self;
    self.gitHubLabel.userInteractionEnabled = YES;
    self.gitHubLabel.text = @"github.com/NordicID/nur_sample_ios";

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    // get the version of NurAPI
    dispatch_async(self.dispatchQueue, ^{
        char buffer[256];
        if ( NurApiGetFileVersion( buffer, 256 ) ) {
            NSString * versionString = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.nurApiVersionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NurAPI version: %@", nil), versionString];
            } );
        }
        else {
            // failed to get version...
            dispatch_async(dispatch_get_main_queue(), ^{
                self.nurApiVersionLabel.text = NSLocalizedString(@"NurAPI version: unknown", nil);
            } );
        }
    } );

    // set up the version and build
    self.appVersionLabel.text =[NSString stringWithFormat:NSLocalizedString(@"App version: %@.%@", nil),
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}


//****************************************************************************************************************
#pragma mark - TTTAttributedLabel delegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}


@end
