
#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"

@interface AboutViewController : UIViewController <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet UILabel * appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel * nurApiVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel * nurApiWrapperVersionLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel * gitHubLabel;

@end
