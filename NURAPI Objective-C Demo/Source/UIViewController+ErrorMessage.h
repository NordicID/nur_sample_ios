
#import <UIKit/UIKit.h>

#import "Log.h"

@interface UIViewController (ErrorMessage)

/**
 * Shows an error dialog with the given error text. The dialog is shown
 * on the UI thread, so that can be called from any thread.
 *
 * @param message the error message.
 **/
- (void) showErrorMessage:(NSString *)message;

/**
 * Shows an error dialog with the text for the NurAPI error code. The dialog is shown
 * on the UI thread, so that can be called from any thread.
 *
 * @param error the NurAPI error code.
 **/
- (void) showNurApiErrorMessage:(int)error;

@end
