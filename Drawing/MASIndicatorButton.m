//
//  MASIndicatorButton.m
//  Drawing
//
//  Created by Augusta Bogie on 3/6/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import "MASIndicatorButton.h"

@implementation MASIndicatorButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{   
    //// Color Declarations
    UIColor* strokeColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0];
    UIColor* color2 = [UIColor colorWithRed: 0.333 green: 0.333 blue: 0.333 alpha: 1];
    
    //// Polygon Drawing
    UIBezierPath* polygonPath = [UIBezierPath bezierPath];
    [polygonPath moveToPoint: CGPointMake(28, 5)];
    [polygonPath addCurveToPoint: CGPointMake(30, 5) controlPoint1: CGPointMake(28, 5) controlPoint2: CGPointMake(29.5, 5)];
    [polygonPath addCurveToPoint: CGPointMake(32, 5) controlPoint1: CGPointMake(30.5, 5) controlPoint2: CGPointMake(32, 5)];
    [polygonPath addLineToPoint: CGPointMake(50, 11)];
    [polygonPath addLineToPoint: CGPointMake(50, 17)];
    [polygonPath addLineToPoint: CGPointMake(32, 12)];
    [polygonPath addLineToPoint: CGPointMake(30, 12)];
    [polygonPath addLineToPoint: CGPointMake(28, 12)];
    [polygonPath addLineToPoint: CGPointMake(10, 17)];
    [polygonPath addLineToPoint: CGPointMake(10, 11)];
    [polygonPath addLineToPoint: CGPointMake(28, 5)];
    [polygonPath closePath];
    polygonPath.lineCapStyle = kCGLineCapRound;
    
    polygonPath.lineJoinStyle = kCGLineJoinBevel;
    
    [color2 setFill];
    [polygonPath fill];
    [strokeColor setStroke];
    polygonPath.lineWidth = 1;
    [polygonPath stroke];
}

@end
