
#import <Foundation/Foundation.h>

@interface ConnectionManager : NSObject

+ (ConnectionManager *) sharedInstance;

/**
 * Should be called when the application is about to terminate. Will disconnect from any reader.
 **/
- (void) applicationTerminating;

/**
 * Should be called when the application is activated, i.e. moved to the foreground and resumed.
 **/
- (void) applicationActivated;

/**
 * Should be called when the application is deactivated, i.e. moved to the background for instance by pressing
 * the home button.
 **/
- (void) applicationDeactivated;

@end
