
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/NurAPIBluetooth.h>

#import "Tag.h"

@interface WriteTagPopoverViewController : UIViewController <UITextFieldDelegate>

// the tag we're about to write
@property (nonatomic, strong) Tag * writeTag;

@property (weak, nonatomic) IBOutlet UILabel *     oldEpcLabel;
@property (weak, nonatomic) IBOutlet UITextField * epcEdit;
@property (weak, nonatomic) IBOutlet UIButton *    writeButton;

@end
