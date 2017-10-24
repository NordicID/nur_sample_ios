
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>
#import "UIViewController+Theme.h"

#import "Tag.h"
#import "ProgressView.h"

@interface LocateTagViewController : UIViewController <BluetoothDelegate>

@property (weak, nonatomic) IBOutlet ProgressView * progressView;
@property (weak, nonatomic) IBOutlet UILabel *  tagLabel;
@property (weak, nonatomic) IBOutlet UIButton * actionButton;
@property (nonatomic, strong)        Tag *      tag;

@end
