
#import "ContactViewController.h"

@interface ContactViewController ()

@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up links
    self.emailLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.emailLabel.delegate = self;
    self.emailLabel.userInteractionEnabled = YES;
    self.emailLabel.text = NSLocalizedString(@"info@nordicid.com", nil);

    self.websiteLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.websiteLabel.delegate = self;
    self.websiteLabel.userInteractionEnabled = YES;
    self.websiteLabel.text = NSLocalizedString(@"www.nordicid.com", nil);

    self.gitHubLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.gitHubLabel.delegate = self;
    self.gitHubLabel.userInteractionEnabled = YES;
    self.gitHubLabel.text = NSLocalizedString(@"On GitHub: github.com/NordicID", nil);

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


@end
