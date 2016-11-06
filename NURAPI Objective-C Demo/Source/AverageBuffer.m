
#import "AverageBuffer.h"

@interface Entry : NSObject
@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, assign) double val;

@end

@implementation Entry
@end


@interface AverageBuffer ()
@property (nonatomic, strong) NSMutableArray * values;
@property (nonatomic, assign) int maxAge;
@property (nonatomic, assign) int maxSize;
@property (nonatomic, readwrite) double avgValue;
@property (nonatomic, readwrite) double sumValue;

@end


@implementation AverageBuffer

- (instancetype)initWithMaxSize:(int)maxSize maxAge:(int)maxAge {
    self = [super init];
    if (self) {
        self.values = [NSMutableArray array];
        self.maxSize = maxSize;
        self.maxAge = maxAge;
        self.avgValue = 0;
        self.sumValue = 0;
    }
    return self;
}


- (void) add:(double)value {
    [self removeOld];

    while (self.values.count >= self.maxSize ) {
        [self.values removeObjectAtIndex:0];
    }

    Entry * entry = [Entry new];
    entry.time = [[NSDate date] timeIntervalSince1970];
    entry.val = value;
    [self.values addObject:entry];

    [self calcAvg];
}


- (void) clear {
    [self.values removeAllObjects];
    self.avgValue = 0;
    self.sumValue = 0;
}


- (void) calcAvg {
    if (self.values.count == 0 ) {
        self.avgValue = 0;
        self.sumValue = 0;
        return;
    }

    double avgVal = 0;

    for ( Entry * tmp in self.values ) {
        avgVal += tmp.val;
    }

    self.sumValue = avgVal;
    self.avgValue = avgVal / (double)self.values.count;
}


- (BOOL) removeOld {
    if ( self.maxAge == 0 ) {
        return NO;
    }

    BOOL ret = NO;

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

    int index = 0;
    while ( index < self.values.count ) {
        Entry * e = self.values[ index ];
        if ( now - e.time > (double)self.maxAge) {
            [self.values removeObjectAtIndex:index];
            ret = YES;
        }
        else {
            index++;
        }
    }

    return ret;
}


@end
