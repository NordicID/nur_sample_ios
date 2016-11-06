
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/NurAPIBluetooth.h>

#import "Tag.h"

@protocol WriteTagPopoverViewControllerDelegate <NSObject>

/**
 * Result method. This is always called on the main UI thread.
 **/
- (void) writeCompletedWithError:(int)error;

@end;


@interface WriteTagPopoverViewController : UIViewController <UITextFieldDelegate>

// the tag we're about to write
@property (nonatomic, strong) Tag * writeTag;

@property (weak, nonatomic) IBOutlet UILabel *     oldEpcLabel;
@property (weak, nonatomic) IBOutlet UITextField * epcEdit;
@property (weak, nonatomic) IBOutlet UIButton *    writeButton;
@property (weak, nonatomic) id<WriteTagPopoverViewControllerDelegate> delegate;


@end
