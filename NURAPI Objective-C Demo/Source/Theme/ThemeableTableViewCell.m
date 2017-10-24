
#import "ThemeableTableViewCell.h"
#import "ThemeManager.h"

@implementation ThemeableTableViewCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupTheme];
    }

    return self;

}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupTheme];
    }

    return self;
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupTheme];
    }

    return self;
}


- (void) setupTheme {
    Theme * theme = [ThemeManager sharedInstance].theme;

    self.backgroundColor = theme.backgroundColor;
    self.tintColor = theme.primaryColor;
}

@end
