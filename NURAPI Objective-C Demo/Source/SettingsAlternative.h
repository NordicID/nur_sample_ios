
#import <Foundation/Foundation.h>

@interface SettingsAlternative : NSObject

//! the title to show for this alternative
@property (nonatomic, strong) NSString * title;

//! the raw NURAPI settings value
@property (nonatomic, assign) int value;

@property (nonatomic, assign) BOOL selected;

+ (instancetype) alternativeWithTitle:(NSString *)title value:(int)value selected:(BOOL)selected;

@end
