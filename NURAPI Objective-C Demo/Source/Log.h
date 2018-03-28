
#import <NurAPIBluetooth/Bluetooth.h>

@interface Log : NSObject <LogDelegate>

@property (nonatomic, assign) BOOL logToConsole;

+ (Log *) sharedInstance;

- (void) debug:(NSString *)message;
- (void) error:(NSString *)message;

- (NSURL *) getFileUrl;

@end

/**
 * Convenience helper functions.
 **/
static void logDebug(NSString * format, ...) {
    va_list args;
    va_start(args, format);
    NSString * formatted = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [[Log sharedInstance] debug:formatted];
}

static void logError(NSString * format, ...) {
    va_list args;
    va_start(args, format);
    NSString * formatted = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [[Log sharedInstance] debug:formatted];
}

