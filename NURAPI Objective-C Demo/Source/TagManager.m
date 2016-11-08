
#import "TagManager.h"
#import "Tag.h"

@interface TagManager ()

@property (nonatomic, strong, readwrite) NSMutableArray * tags;
@property (nonatomic, strong) NSMutableSet *              tagIds;

@end

@implementation TagManager

+ (TagManager *) sharedInstance {
    static TagManager * instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        instance = [[TagManager alloc] init];
    });

    // return the instance
    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.tags = [NSMutableArray array];
        self.tagIds = [NSMutableSet set];
    }

    return self;
}


- (BOOL) addTag:(Tag *)tag {
    if ( tag && ! [self.tagIds containsObject:tag.hex ] ) {
        // a new tag
        [self.tags addObject:tag];
        [self.tagIds addObject:tag.hex];
        return YES;
    }

    // find our tag
    for ( Tag * old in self.tags ) {
        if ( [tag.hex isEqualToString:old.hex] ) {
            // found the old one
            old.foundCount++;
            break;
        }
    }

    return NO;
}


- (void) clear {
    // simply clear all the tags we have
    [self.tags removeAllObjects];
    [self.tagIds removeAllObjects];
}


@end
