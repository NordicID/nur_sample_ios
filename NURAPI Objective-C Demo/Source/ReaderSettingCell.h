
#import <UIKit/UIKit.h>

#import "ThemeableTableViewCell.h"

typedef enum {
    kHidBarcodeEnabled = 0,
    kHidRfidEnabled = 1,
    kWirelessChargingEnabled = 2,
} ReaderSettingType;

/**
 * Delegate for letting the cell inform the owner that the setting has changed.
 **/
@protocol ReaderSettingDelegate <NSObject>

- (void) setting:(ReaderSettingType)setting hasChanged:(BOOL)enabled;

@end


@interface ReaderSettingCell : ThemeableTableViewCell

@property (nonatomic, assign)        ReaderSettingType settingType;
@property (nonatomic, assign)        BOOL              settingEnabled;
@property (weak, nonatomic) IBOutlet UILabel *         titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *        enabledSwitch;

// optional delegate
@property (nonatomic, weak) id<ReaderSettingDelegate> delegate;

@end
