
#import <Foundation/Foundation.h>
#import "Theme.h"

@interface ThemeManager : NSObject

@property (nonatomic, strong) Theme * theme;

+ (ThemeManager *) sharedInstance;

@end
