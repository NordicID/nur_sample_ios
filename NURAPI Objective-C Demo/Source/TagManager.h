
#import <Foundation/Foundation.h>

#import "Tag.h"


@interface TagManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray * tags;

+ (TagManager *) sharedInstance;

- (void) addTag:(Tag *)tag;

- (void) clear;

@end
