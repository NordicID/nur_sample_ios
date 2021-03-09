
#import <NurAPIBluetooth/Bluetooth.h>

@interface Log : NSObject <LogDelegate>

@property (nonatomic, assign) BOOL logToConsole;
@property (nonatomic, assign) BOOL logToFile;

+ (Log *) sharedInstance;

- (void) debug:(NSString *)message;
- (void) error:(NSString *)message;

- (NSURL *) getFileUrl;

@end

/**
 * Convenience helper functions.
 **/
void logDebug(NSString * format, ...);
void logError(NSString * format, ...);

