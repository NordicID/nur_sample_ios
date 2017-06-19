
#import <Foundation/Foundation.h>

#import "Tag.h"


@interface TagManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray * tags;

+ (TagManager *) sharedInstance;

// Retrieves a tag with the given index from the reader. Returns nil on error.
- (Tag *) getTag:(int)tagIndex;

// Adds a tag. Returns YES if the tag was new and NO if it was already found.
- (BOOL) addTag:(Tag *)tag;

- (void) lock;
- (void) unlock;

- (void) clear;

@end
