
#import "QuickGuideViewController.h"

@interface QuickGuideViewController ()

@end

@implementation QuickGuideViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"QuickGuide" ofType:@"html"];
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    [self.webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
}

@end
