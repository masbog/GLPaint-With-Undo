//
//  MASImageBlurr.h
//  Drawing
//
//  Created by Augusta Bogie on 3/8/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MASImageBlurr : NSObject
+ (UIImage*) blur:(UIImage*)theImage;
+ (UIImage*) scaleIfNeeded:(CGImageRef)cgimg;
+ (UIImage*) reOrientIfNeeded:(UIImage*)theImage;
@end
