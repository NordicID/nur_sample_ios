
#import <UIKit/UIKit.h>

#import "Tag.h"

@interface LocateTagViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *  tagLabel;
@property (weak, nonatomic) IBOutlet UILabel *  strengthLabel;
@property (weak, nonatomic) IBOutlet UIButton * actionButton;
@property (nonatomic, strong)        Tag *      tag;

@end
