
#import "ContactViewController.h"

@interface ContactViewController ()

@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.parentViewController.navigationItem.title = @"Contact";

    // set up links
    self.emailLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.emailLabel.delegate = self;
    self.emailLabel.userInteractionEnabled = YES;
    self.emailLabel.text = @"info@nordicid.com";

    self.websiteLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.websiteLabel.delegate = self;
    self.websiteLabel.userInteractionEnabled = YES;
    self.websiteLabel.text = @"www.nordicid.com";

    self.gitHubLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.gitHubLabel.delegate = self;
    self.gitHubLabel.userInteractionEnabled = YES;
    self.gitHubLabel.text = @"On GitHub: github.com/NordicID";

}


//****************************************************************************************************************
#pragma mark - TTTAttributedLabel delegate


- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}


@end
