
#import "SmoothingBuffer.h"

@interface SmoothingBuffer () {
    int * values;
    int count;
}

@end

@implementation SmoothingBuffer

- (instancetype)initWithSize:(unsigned int)size {
    self = [super init];
    if (self) {
        values = malloc( size * sizeof(int) );
        memset( values, 0, size * sizeof(int) );
        count = size;
    }

    return self;
}


- (int) add:(int)value {
    int sum = 0;

    // copy old values forward
    for ( int index = count - 2; index >= 0; --index ) {
        values[index + 1] = values[ index ];
        sum += values[ index + 1];
    }

    values[0] = value;
    sum += value;

    return (int)( (float)sum / (float)count );
}

@end
