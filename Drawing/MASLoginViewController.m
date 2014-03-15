//
//  MASLoginViewController.m
//  Drawing
//
//  Created by Augusta Bogie on 3/7/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import "MASLoginViewController.h"
#import "MASImageBlurr.h"
#import <QuartzCore/QuartzCore.h>
#import "MASAppDelegate.h"

@interface MASLoginViewController ()
{
    CGPoint svos;
}
@end

@implementation MASLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    self.bgImageView.image = [MASImageBlurr blur:[UIImage imageNamed:@"forest.png"]];
    self.loginContainerView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.6];
    self.loginContainerView.layer.masksToBounds = YES;
    self.loginContainerView.layer.cornerRadius = 5;
    // Do any additional setup after loading the view from its nib.
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect frame = self.loginContainerView.frame;
    svos = frame.origin;
    frame.origin.y -= 100;
    [UIView animateWithDuration:0.4 animations:^{
        self.loginContainerView.frame = frame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect frame = self.loginContainerView.frame;
    frame.origin = svos;
    [UIView animateWithDuration:0.4 animations:^{
        self.loginContainerView.frame = frame;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)hideMe:(id)sender
{
    for (UITextField *txtField in self.loginContainerView.subviews) {
        [txtField resignFirstResponder];
    }
}

- (IBAction)doLogin:(id)sender
{
    MASAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate switchViewController];
}

- (IBAction)doSignUp:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"Sorry This feature not yet completed" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}
@end
