//
//  MASAppDelegate.m
//  Drawing
//
//  Created by Augusta Bogie on 3/6/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import "MASAppDelegate.h"

@implementation MASAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.splashView = [[UIView alloc] initWithFrame:self.window.bounds];
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:self.window.bounds];
    imgV.image = [UIImage imageNamed:@"me"];
    [self.splashView addSubview:imgV];
    
    self.mVC = [[MASDrawingViewController alloc] initWithNibName:@"MASDrawingViewController" bundle:nil];
    self.mLVC = [[MASLoginViewController alloc] initWithNibName:@"MASLoginViewController" bundle:nil];
    self.navCon = [[UINavigationController alloc] initWithRootViewController:self.mVC];
    
    self.window.rootViewController = self.mLVC;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)removeSplash
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                           forView:self.window
                             cache:YES];
    
    [self.splashView removeFromSuperview];
    [UIView commitAnimations];
    self.window.rootViewController = self.navCon;
}

- (void)switchViewController
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                           forView:self.window
                             cache:YES];
    
    [self.window addSubview:self.splashView];
    [UIView commitAnimations];
    [self performSelector:@selector(removeSplash) withObject:nil afterDelay:2];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
