
#import <UIKit/UIKit.h>

/**
 * Defines a theme that can set up a target specific visual appearance. Each target must have an
 * implementation that implements all methods.
 **/
@interface Theme : NSObject

@property (nonatomic, strong) UIColor * backgroundColor;
@property (nonatomic, strong) UIColor * primaryColor;
@property (nonatomic, strong) UIColor * secondaryColor;
@property (nonatomic, strong) UIColor * lightTextColor;
@property (nonatomic, strong) UIColor * darkTextColor;

// textual theming
@property (nonatomic, strong) NSString * applicationTitle;

@end
