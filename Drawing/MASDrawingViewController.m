//
//  MASDrawingViewController.m
//  Drawing
//
//  Created by Augusta Bogie on 3/9/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import "MASDrawingViewController.h"
#import "HRColorPickerViewController.h"
#import "PaintingView.h"

//CONSTANTS:

#define kBrightness             1.0
#define kSaturation             0.45

#define kPaletteHeight			30
#define kPaletteSize			5
#define kMinEraseInterval		0.5

@interface MASDrawingViewController ()<HRColorPickerViewControllerDelegate>
{
    HRColorPickerViewController *colorPicker;
    UIPopoverController *colorPickerPopover;
    UIColor *selectedColor;
    
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat opacity;
    
    int currentDrawingType;
    
    NSArray *toolImageDisable;
    NSArray *toolImageEnable;
    
    CFTimeInterval		lastTime;
}
@property (weak, nonatomic) IBOutlet UIView *panelDrawingView;
@property (weak, nonatomic) IBOutlet UIButton *indicatorButton;
@property (weak, nonatomic) IBOutlet UISlider *sizeSlider;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *currentSizeIndicator;
@property (weak, nonatomic) IBOutlet PaintingView *workspacePaintingView;

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
    
    currentDrawingType = 203;
    for (int i = 200; i<=204; i++) {
        UIButton *tempButton = (UIButton *)[self.view viewWithTag:i];
        [tempButton addTarget:self action:@selector(setDrawingType:) forControlEvents:UIControlEventTouchUpInside];
        if (currentDrawingType == i) {
            [tempButton setBackgroundImage:[UIImage imageNamed:[toolImageEnable objectAtIndex:i-200]] forState:UIControlStateNormal];
        }else{
            [tempButton setBackgroundImage:[UIImage imageNamed:[toolImageDisable objectAtIndex:i-200]] forState:UIControlStateNormal];
        }
    }
    
    [(PaintingView *)self.workspacePaintingView setBackgroundColor:[UIColor whiteColor]];
    
    [(PaintingView *)self.workspacePaintingView setBrushScale:3];
    [(PaintingView *)self.workspacePaintingView setBrushStep:0.5];
    [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:red green:green blue:blue];
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
    }else{
        red = 0;
        green = 0;
        blue = 0;
        opacity = 1;
    }
    
    if (currentDrawingType == 200) {
        [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:1 green:1 blue:1 alpha:1];
    }else if (currentDrawingType == 201){
        [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8];
    }else{
        [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:red green:green blue:blue alpha:opacity];
    }
    
    selectedColor = color;
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
    
    switch (button.tag) {
        case 200:
        {
            [(PaintingView *)self.workspacePaintingView setBgTextTure:0];
            [(PaintingView *)self.workspacePaintingView setBrushScale:1];
            [(PaintingView *)self.workspacePaintingView setBrushStep:1];
            [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:1 green:1 blue:1 alpha:1];
        }
            break;
        case 201:
        {
            [(PaintingView *)self.workspacePaintingView setBgTextTure:1];
            [(PaintingView *)self.workspacePaintingView setBrushScale:15];
            [(PaintingView *)self.workspacePaintingView setBrushStep:2];
            [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:red*0.2 green:green*0.2 blue:blue*0.2 alpha:0.8];
        }
            break;
        case 202:
        {
            [(PaintingView *)self.workspacePaintingView setBgTextTure:2];
            [(PaintingView *)self.workspacePaintingView setBrushScale:20];
            [(PaintingView *)self.workspacePaintingView setBrushStep:0.1];
            [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:red green:green blue:blue alpha:1];
        }
            break;
        case 203:
        {
            [(PaintingView *)self.workspacePaintingView setBgTextTure:3];
            [(PaintingView *)self.workspacePaintingView setBrushScale:3];
            [(PaintingView *)self.workspacePaintingView setBrushStep:0.5];
            [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:red green:green blue:blue alpha:1];
        }
            break;
        case 204:
        {
            [(PaintingView *)self.workspacePaintingView setBgTextTure:4];
            [(PaintingView *)self.workspacePaintingView setBrushScale:1];
            [(PaintingView *)self.workspacePaintingView setBrushStep:10];
            [(PaintingView *)self.workspacePaintingView setBrushColorWithRed:red green:green blue:blue alpha:opacity];
        }
            break;
            
        default:
            break;
    }
    
}

- (IBAction)changeSize:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    self.currentSizeIndicator.title = [NSString stringWithFormat:@"%d", (int)slider.value];
}

- (IBAction)clearAll:(id)sender
{
    [(PaintingView *)self.workspacePaintingView erase];
}

- (IBAction)undo:(id)sender
{
    [(PaintingView *)self.workspacePaintingView undo];
}
@end
