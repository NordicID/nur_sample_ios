
#import "ContactViewController.h"
#import "Log.h"

@interface ContactViewController ()

@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // load the meta data plist from the bundle
    NSString* path = [[NSBundle mainBundle] pathForResource:@"MetaData" ofType:@"plist"];

    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
        logDebug( @"no MetaData.plist file found in bundle");
        return;
    }

    NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile: path];

    // company name
    self.companyLabel.text = [metadata objectForKey:@"companyName"];
    self.addressLabel1.text = [metadata objectForKey:@"address1"];
    self.addressLabel2.text = [metadata objectForKey:@"address2"];
    self.addressLabel3.text = [metadata objectForKey:@"address3"];

    self.phoneLabel.enabledTextCheckingTypes = NSTextCheckingTypePhoneNumber;
    self.phoneLabel.delegate = self;
    self.phoneLabel.userInteractionEnabled = YES;
    self.phoneLabel.text = [metadata objectForKey:@"phone"];

    self.faxLabel.enabledTextCheckingTypes = NSTextCheckingTypePhoneNumber;
    self.faxLabel.delegate = self;
    self.faxLabel.userInteractionEnabled = YES;
    self.faxLabel.text = [metadata objectForKey:@"fax"];

    self.emailLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.emailLabel.delegate = self;
    self.emailLabel.userInteractionEnabled = YES;
    self.emailLabel.text = [metadata objectForKey:@"email"];

    self.websiteLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.websiteLabel.delegate = self;
    self.websiteLabel.userInteractionEnabled = YES;
    self.websiteLabel.text = [metadata objectForKey:@"website"];

    self.gitHubLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.gitHubLabel.delegate = self;
    self.gitHubLabel.userInteractionEnabled = YES;
    self.gitHubLabel.text = [metadata objectForKey:@"gitHubUrl"];

}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Contact", nil);
}



//****************************************************************************************************************
#pragma mark - TTTAttributedLabel delegate


- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}


- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    // clean up the phone number from "+358 12-3456 78" to "tel:35812345678"
    NSString * cleanPhoneNumber = [@"tel:" stringByAppendingString:phoneNumber];
    cleanPhoneNumber = [cleanPhoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    cleanPhoneNumber = [cleanPhoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    cleanPhoneNumber = [cleanPhoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];

    logDebug( @"clean phone number: %@", cleanPhoneNumber );

    // do the call
    NSURL * phoneNumberUrl = [NSURL URLWithString:cleanPhoneNumber];
    [[UIApplication sharedApplication] openURL:phoneNumberUrl];
}

@end
