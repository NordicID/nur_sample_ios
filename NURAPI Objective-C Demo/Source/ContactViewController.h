
#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"
#import "UIViewController+Theme.h"

@interface ContactViewController : UIViewController <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet TTTAttributedLabel * emailLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * websiteLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * gitHubLabel;

@end
