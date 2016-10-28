
#import <UIKit/UIKit.h>

#import "Tag.h"

@interface LocateTagViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel * tagLabel;
@property (nonatomic, strong)        Tag *     tag;

@end
