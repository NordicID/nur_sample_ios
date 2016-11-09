
#import "ProgressView.h"

@implementation ProgressView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];

        // Determine our start and stop angles for the arc (in radians)
        self.startAngle = M_PI * 1.5;
        self.endAngle = self.startAngle + (M_PI * 2);

    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    // Display our percentage as a string
    NSString* textContent = [NSString stringWithFormat:@"%.1f", self.percent];

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];

    // Create our arc, with the correct angles
    [bezierPath addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                          radius:130
                      startAngle:self.startAngle
                        endAngle:(self.endAngle - self.startAngle) * (self.percent / 100.0) + self.startAngle
                       clockwise:YES];

    // Set the display for the path, and stroke it
    bezierPath.lineWidth = 20;
    [[UIColor redColor] setStroke];
    [bezierPath stroke];

    // Text Drawing
    CGRect textRect = CGRectMake((rect.size.width / 2.0) - 71/2.0, (rect.size.height / 2.0) - 45/2.0, 71, 45);
    [[UIColor blackColor] setFill];
    [textContent drawInRect: textRect
                   withFont: [UIFont fontWithName: @"Helvetica-Bold" size: 42.5]
              lineBreakMode: NSLineBreakByWordWrapping
                  alignment: NSTextAlignmentCenter];

        [@"Hello" drawInRect:rect withAttributes:@{NSForegroundColorAttributeName : [UIColor redColor],
                                              NSFontAttributeName            : [UIFont systemFontOfSize:24]}];

}

@end

