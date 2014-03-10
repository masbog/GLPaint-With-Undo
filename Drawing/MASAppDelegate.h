//
//  MASAppDelegate.h
//  Drawing
//
//  Created by Augusta Bogie on 3/6/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MASDrawingViewController.h"
#import "MASLoginViewController.h"

@interface MASAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navCon;
@property (strong, nonatomic) MASDrawingViewController *mVC;
@property (strong, nonatomic) MASLoginViewController *mLVC;
@end
