
#import <UIKit/UIKit.h>

#import "Tag.h"

@interface TagViewController : UIViewController

@property (nonatomic, strong) Tag * tag;
@property (nonatomic, assign) unsigned int rounds;

@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIButton *    locateTagButton;

@end
