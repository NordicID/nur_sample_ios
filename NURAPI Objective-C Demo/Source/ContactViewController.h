
#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"
#import "UIViewController+Theme.h"

@interface ContactViewController : UIViewController <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet UILabel *            companyLabel;
@property (weak, nonatomic) IBOutlet UILabel *            addressLabel1;
@property (weak, nonatomic) IBOutlet UILabel *            addressLabel2;
@property (weak, nonatomic) IBOutlet UILabel *            addressLabel3;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * emailLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * phoneLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * faxLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * websiteLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * gitHubLabel;

@end
