
#import <NurAPIBluetooth/NurAPIBluetooth.h>

#import "AboutViewController.h"
#import "Log.h"


@interface AboutViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end


@implementation AboutViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // load the meta data plist from the bundle
    NSString* path = [[NSBundle mainBundle] pathForResource:@"MetaData" ofType:@"plist"];

    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
        logDebug( @"no MetaData.plist file found in bundle");
    }
    else {
        NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile: path];

        // company name
        self.companyLabel.text = [metadata objectForKey:@"about"];

        // optional GitHub url
        NSString * gitHubUrl = [metadata objectForKey:@"gitHubUrl"];

        if ( gitHubUrl.length > 0 ) {
            // set up links
            self.gitHubLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
            self.gitHubLabel.delegate = self;
            self.gitHubLabel.userInteractionEnabled = YES;
            self.gitHubLabel.text = gitHubUrl;
        }
        else {
            self.gitHubLabel.hidden = YES;
        }
    }

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    // get the version of NurAPI
    dispatch_async(self.dispatchQueue, ^{
        char buffer[256];
        if ( NurApiGetFileVersion( buffer, 256 ) ) {
            NSString * versionString = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.nurApiVersionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NUR API version: %@", nil), versionString];
            } );
        }
        else {
            // failed to get version...
            dispatch_async(dispatch_get_main_queue(), ^{
                self.nurApiVersionLabel.text = NSLocalizedString(@"NUR API version: unknown", nil);
            } );
        }
    } );

    // set up the version and build
    self.appVersionLabel.text =[NSString stringWithFormat:NSLocalizedString(@"App version: %@.%@", nil),
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];

    self.nurApiWrapperVersionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NurAPI wrapper version: %d", nil), NURAPIBLUETOOTH_VERSION];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"About", nil);
}


//****************************************************************************************************************
#pragma mark - TTTAttributedLabel delegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}


@end
