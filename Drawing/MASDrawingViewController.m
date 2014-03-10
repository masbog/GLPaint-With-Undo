//
//  MASDrawingViewController.m
//  Drawing
//
//  Created by Augusta Bogie on 3/9/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import "MASDrawingViewController.h"
#import "HRColorPickerViewController.h"

@interface MASDrawingViewController ()<HRColorPickerViewControllerDelegate>
{
    HRColorPickerViewController *colorPicker;
    UIPopoverController *colorPickerPopover;
    UIColor *selectedColor;
    
    CGPoint lastPoint;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat brush;
    CGFloat opacity;
    BOOL mouseSwiped;
    
    int currentDrawingType;
    
    NSArray *toolImageDisable;
    NSArray *toolImageEnable;
}
@property (weak, nonatomic) IBOutlet UIView *panelDrawingView;
@property (weak, nonatomic) IBOutlet UIButton *indicatorButton;
@property (weak, nonatomic) IBOutlet UIImageView *tempDrawImage;
@property (weak, nonatomic) IBOutlet UIImageView *mainImage;
@property (weak, nonatomic) IBOutlet UISlider *sizeSlider;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *currentSizeIndicator;

@end

@implementation MASDrawingViewController

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
    [self.navigationController.navigationBar.topItem setTitle:@"Drawing"];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Library" style:UIBarButtonItemStyleDone target:nil action:nil];
    [self.navigationController.navigationBar.topItem setRightBarButtonItem:rightBarButton];
    
    selectedColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    colorPicker = [HRColorPickerViewController fullColorPickerViewControllerWithColor:selectedColor];
    colorPicker.delegate = self;
    colorPickerPopover = [[UIPopoverController alloc] initWithContentViewController:colorPicker];
    [colorPickerPopover setPopoverContentSize:CGSizeMake(320, 480) animated:NO];
    
    red = 0.0/255.0;
    green = 0.0/255.0;
    blue = 0.0/255.0;
    brush = 1.0;
    opacity = 0.8f;
    
    self.sizeSlider.value = 1.0;
    
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.panelDrawingView.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: (CGSize){10.0, 10.}].CGPath;
    
    self.panelDrawingView.layer.mask = maskLayer;
    
    toolImageDisable = [[NSArray alloc] initWithObjects:
                        @"Sketches.tool.eraser.off.png",
                        @"Sketches.tool.criterium.off.png",
                        @"Sketches.tool.rotring.off.png",
                        @"Sketches.tool.pen.ink02.off.png",
                        @"Sketches.tool.paint.fine.off.png",
                        @"Sketches.tool.airbrush.off.png",
                        @"Sketches.tool.crayon01.Off.png",
                        @"Sketches.tool.letraset.patterns.off.png",
                        @"Sketches.tool.paint.large.off.png",
                        @"Sketches.tool.pen.paint.off.png", nil];
    
    toolImageEnable = [[NSArray alloc] initWithObjects:
                        @"Sketches.tool.eraser.on.png",
                        @"Sketches.tool.criterium.on.png",
                        @"Sketches.tool.rotring.on.png",
                        @"Sketches.tool.pen.ink02.on.png",
                        @"Sketches.tool.paint.fine.on.png",
                        @"Sketches.tool.airbrush.on.png",
                        @"Sketches.tool.crayon01.on.png",
                        @"Sketches.tool.letraset.patterns.png",
                        @"Sketches.tool.paint.large.on.png",
                        @"Sketches.tool.pen.paint.on.png", nil];
    
    currentDrawingType = 201;
    for (int i = 200; i<=204; i++) {
        UIButton *tempButton = (UIButton *)[self.view viewWithTag:i];
        [tempButton addTarget:self action:@selector(setDrawingType:) forControlEvents:UIControlEventTouchUpInside];
        if (currentDrawingType == i) {
            [tempButton setBackgroundImage:[UIImage imageNamed:[toolImageEnable objectAtIndex:i-200]] forState:UIControlStateNormal];
        }else{
            [tempButton setBackgroundImage:[UIImage imageNamed:[toolImageDisable objectAtIndex:i-200]] forState:UIControlStateNormal];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    CGRect frame = self.panelDrawingView.frame;
    frame.origin.y = self.view.window.bounds.size.width;
    self.panelDrawingView.frame = frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ShowHideMenu:(id)sender
{
    CGRect panelFrame = self.panelDrawingView.frame;
    CGRect frame = self.indicatorButton.frame;
    if (!self.indicatorButton.selected) {
        frame.origin.y -= 160;
        panelFrame.origin.y -= 160;
    }else{
        frame.origin.y += 160;
        panelFrame.origin.y += 160;
    }
    
    self.indicatorButton.selected = !self.indicatorButton.selected;
    [UIView animateWithDuration:0.4 animations:^{
        self.indicatorButton.frame = frame;
        self.panelDrawingView.frame = panelFrame;
    } completion:^(BOOL finished) {
    }];
}

- (IBAction)showColorPicker:(id)sender
{
    if ([colorPickerPopover isPopoverVisible]) {
        [colorPickerPopover dismissPopoverAnimated:YES];
        return;
    }
    UIButton *button = (UIButton *)sender;
    CGRect buttonRect = [button convertRect:button.frame toView:self.view];
    buttonRect.origin.x -= 20;
    [colorPickerPopover presentPopoverFromRect:buttonRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)setSelectedColor:(UIColor*)color
{
    [self changeSelectedColor:color];
}

- (void)changeSelectedColor:(UIColor *)color
{
    CGColorRef colorRef = [color CGColor];
    int _countComponents = CGColorGetNumberOfComponents(colorRef);
    
    if (_countComponents == 4) {
        const CGFloat *_components = CGColorGetComponents(colorRef);
        CGFloat aRed     = _components[0];
        red = aRed;
        CGFloat aGreen = _components[1];
        green = aGreen;
        CGFloat aBlue   = _components[2];
        blue = aBlue;
        CGFloat aAlpha = _components[3];
        opacity = aAlpha;
    }
    
    selectedColor = color;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self.view];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    mouseSwiped = YES;
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.view];
    
    switch (currentDrawingType) {
        case eraserDrawing:
        {
            
            UIGraphicsBeginImageContext(self.view.frame.size);
            [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush );
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1, 1, 1, 1);
            
            //CGContextSetShadow(UIGraphicsGetCurrentContext(), CGSizeMake(0, 5), 10);
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
            
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
            [self.tempDrawImage setAlpha:opacity];
            UIGraphicsEndImageContext();
        }
            break;
        case pencilDrawing:
        case penDrawing:
        {
            UIGraphicsBeginImageContext(self.view.frame.size);
            [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush );
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, opacity);
            
            //CGContextSetShadow(UIGraphicsGetCurrentContext(), CGSizeMake(0, 5), 10);
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
            
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
            [self.tempDrawImage setAlpha:opacity];
            UIGraphicsEndImageContext();
        }
        case brushDrawing:
        {
            
            
        }
            break;
        default:
            break;
    }
    
    lastPoint = currentPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(!mouseSwiped) {
        switch (currentDrawingType) {
            case eraserDrawing:
            {
                UIGraphicsBeginImageContext(self.view.frame.size);
                [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
                CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
                CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1, 1, 1, 1);
                CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
                CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
                CGContextStrokePath(UIGraphicsGetCurrentContext());
                CGContextFlush(UIGraphicsGetCurrentContext());
                self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
                break;
            case pencilDrawing:
            case penDrawing:
            {
                UIGraphicsBeginImageContext(self.view.frame.size);
                [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
                CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
                CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, opacity);
                
                CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
                CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
                CGContextStrokePath(UIGraphicsGetCurrentContext());
                CGContextFlush(UIGraphicsGetCurrentContext());
                self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
                break;
            case brushDrawing:
            {
                
            }
                break;
                
            default:
                break;
        }
    }
    
    UIGraphicsBeginImageContext(self.mainImage.frame.size);
    [self.mainImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:opacity];
    self.mainImage.image = UIGraphicsGetImageFromCurrentImageContext();
    self.tempDrawImage.image = nil;
    UIGraphicsEndImageContext();
}


- (IBAction)changeColor:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch (button.tag)
    {
        case 101:
        {
            [self changeSelectedColor:[UIColor blackColor]];
        }
            break;
        case 102:
        {
            [self changeSelectedColor:[UIColor blueColor]];
        }
            break;
        case 103:
        {
            [self changeSelectedColor:[UIColor brownColor]];
        }
            break;
        case 104:
        {
            [self changeSelectedColor:[UIColor cyanColor]];
        }
            break;
        case 105:
        {
            [self changeSelectedColor:[UIColor greenColor]];
        }
            break;
        case 106:
        {
            [self changeSelectedColor:[UIColor magentaColor]];
        }
            break;
        case 107:
        {
            [self changeSelectedColor:[UIColor orangeColor]];
        }
            break;
        case 108:
        {
            [self changeSelectedColor:[UIColor purpleColor]];
        }
            break;
        case 109:
        {
            [self changeSelectedColor:[UIColor redColor]];
        }
            break;
        case 110:
        {
            [self changeSelectedColor:[UIColor yellowColor]];
        }
            break;
            
        default:
            break;
    }
    
    for (int i = 101; i<= 110; i++) {
        if (i != button.tag) {
            UIButton *tempButton = (UIButton *)[self.view viewWithTag:i];
            tempButton.layer.masksToBounds = YES;
            tempButton.layer.borderColor = [UIColor clearColor].CGColor;
            tempButton.layer.borderWidth = 0;
        }else{
            button.layer.masksToBounds = YES;
            button.layer.borderColor = [UIColor whiteColor].CGColor;
            button.layer.borderWidth = 3;
            
        }
    }
    
}

- (IBAction)setDrawingType:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if (button.tag == pencilDrawing)
    {
        opacity = 0.8f;
    }else{
        opacity = 1.0f;
    }
    
    UIButton *tempButton = (UIButton *)[self.view viewWithTag:currentDrawingType];
    [tempButton setBackgroundImage:[UIImage imageNamed:[toolImageDisable objectAtIndex:currentDrawingType-200]] forState:UIControlStateNormal];
    currentDrawingType = button.tag;
    [button setBackgroundImage:[UIImage imageNamed:[toolImageEnable objectAtIndex:button.tag-200]] forState:UIControlStateNormal];
}

- (IBAction)changeSize:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    self.currentSizeIndicator.title = [NSString stringWithFormat:@"%d", (int)slider.value];
    brush = slider.value;
}

- (IBAction)clearAll:(id)sender
{
    self.mainImage.image = nil;
}
@end
