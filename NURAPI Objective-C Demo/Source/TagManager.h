
#import <Foundation/Foundation.h>

#import "Tag.h"


@interface TagManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray * tags;

+ (TagManager *) sharedInstance;

// Adds a tag. Returns YES if the tag was new and NO if it was already found.
- (BOOL) addTag:(Tag *)tag;

- (void) clear;

@end
