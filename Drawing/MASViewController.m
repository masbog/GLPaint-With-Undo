//
//  MASViewController.m
//  Drawing
//
//  Created by Augusta Bogie on 3/6/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import "MASViewController.h"
#import "MASIndicatorButton.h"

@interface MASViewController ()

@end

@implementation MASViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ShowHideMenu:(id)sender
{
    MASIndicatorButton *mIB = (MASIndicatorButton *)sender;
    CGRect frame = mIB.frame;
    if (!mIB.selected) {
        frame.origin.y -= 100;
    }else{
        frame.origin.y += 100;
    }
    
    mIB.selected = !mIB.selected;
    [UIView animateWithDuration:0.4 animations:^{
        mIB.frame = frame;
    }];
}


@end
