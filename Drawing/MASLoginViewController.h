//
//  MASLoginViewController.h
//  Drawing
//
//  Created by Augusta Bogie on 3/7/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MASLoginViewController : UIViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;
- (IBAction)hideMe:(id)sender;
- (IBAction)doLogin:(id)sender;
- (IBAction)doSignUp:(id)sender;

@end
