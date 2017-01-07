
#import "ProgressView.h"

@implementation ProgressView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];

        // Determine our start and stop angles for the arc (in radians)
        self.startAngle = M_PI * 0.75;
        self.endAngle = M_PI * 2 + M_PI * 0.25; //self.startAngle + (M_PI * 2);

        // default to 0 %
        self.percent = 0;
    }

    return self;
}


- (void) setPercent:(double)percent {
    _percent = percent;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    NSString* textContent = [NSString stringWithFormat:@"%.0f%%", self.percent];

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];

    // Create our arc, with the correct angles
    [bezierPath addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                          radius:80
                      startAngle:self.startAngle
                        endAngle:self.startAngle + (self.endAngle - self.startAngle) * (self.percent / 100.0)
                       clockwise:YES];

    // Set the display for the path, and stroke it
    bezierPath.lineWidth = 20;
    [[UIColor blackColor] setStroke];
    [bezierPath stroke];
    [bezierPath closePath];
    
    // Text Drawing
    [[UIColor blackColor] setFill];

    /// Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    // wanted font
    UIFont * font = [UIFont boldSystemFontOfSize:42];
    NSDictionary *attributes = @{NSFontAttributeName:font, //[UIFont fontWithName: @"Helvetica-Bold" size: 42.5],
                                 NSParagraphStyleAttributeName: paragraphStyle};

    // get the size of the rendered text and set up a centered rect
    CGSize size = [textContent sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake(rect.origin.x,
                         rect.origin.y + (rect.size.height - size.height)/2,
                         rect.size.width,
                         (rect.size.height - size.height)/2);

    [textContent drawInRect:textRect withAttributes:attributes];
}

@end

