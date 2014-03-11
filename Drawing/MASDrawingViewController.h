//
//  MASDrawingViewController.h
//  Drawing
//
//  Created by Augusta Bogie on 3/9/14.
//  Copyright (c) 2014 Augusta Bogie. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    eraserDrawing = 200,
    pencilDrawing,
    penDrawing,
    brushDrawing
} DrawingType;


@interface MASDrawingViewController : UIViewController
- (IBAction)showColorPicker:(id)sender;
- (IBAction)changeColor:(id)sender;
- (IBAction)setDrawingType:(id)sender;
- (IBAction)changeSize:(id)sender;
- (IBAction)clearAll:(id)sender;
- (IBAction)undo:(id)sender;

@end
