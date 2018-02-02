
#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"
#import "UIViewController+Theme.h"

@interface AboutViewController : UIViewController <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet UILabel * companyLabel;
@property (weak, nonatomic) IBOutlet UILabel * appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel * nurApiVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel * nurApiWrapperVersionLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * gitHubLabel;

@end
