
#import <Foundation/Foundation.h>

/**
 * Simple buffer that smooths a set of noisy values by averaging them together. If the buffer is set to hold 10
 * values it will keep the last added 10 values and return a smoothed value when adding a new value. This makes
 * noisy values a bit less jumpy.
 **/
@interface SmoothingBuffer : NSObject

- (instancetype)initWithSize:(unsigned int)size;

- (int) add:(int)value;

@end
