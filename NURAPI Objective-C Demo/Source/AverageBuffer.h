
#import <Foundation/Foundation.h>

@interface AverageBuffer : NSObject

@property (nonatomic, readonly) double avgValue;
@property (nonatomic, readonly) double sumValue;

- (instancetype)initWithMaxSize:(int)maxSize maxAge:(int)maxAge;

- (void) add:(double)value;

- (void) clear;

@end
