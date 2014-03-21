/*
     File: PaintingView.m
 Abstract: The class responsible for the finger painting. The class wraps the 
 CAEAGLLayer from CoreAnimation into a convenient UIView subclass. The view 
 content is basically an EAGL surface you render your OpenGL scene into.
  Version: 1.12
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

#import "PaintingView.h"
#import "shaderUtil.h"
#import "fileUtil.h"
#import "debug.h"

// Shaders
enum {
    PROGRAM_POINT,
    NUM_PROGRAMS
};

enum {
	UNIFORM_MVP,
    UNIFORM_POINT_SIZE,
    UNIFORM_VERTEX_COLOR,
    UNIFORM_TEXTURE,
	NUM_UNIFORMS
};

enum {
	ATTRIB_VERTEX,
	NUM_ATTRIBS
};

typedef struct {
	char *vert, *frag;
	GLint uniform[NUM_UNIFORMS];
	GLuint id;
} programInfo_t;

programInfo_t program[NUM_PROGRAMS] = {
    { "point.vsh",   "point.fsh" },     // PROGRAM_POINT
};


// Texture
typedef struct {
    GLuint id;
    GLsizei width, height;
} textureInfo_t;


@interface PaintingView()
{
	// The pixel dimensions of the backbuffer
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	// OpenGL names for the renderbuffer and framebuffers used to render to this view
	GLuint viewRenderbuffer, viewFramebuffer;
    
    // OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
    GLuint depthRenderbuffer;
	
	textureInfo_t brushTexture;     // brush texture
    CGFloat brushColor[4];          // brush color
    
	Boolean	firstTouch;
	Boolean needsErase;
    
    // Shader objects
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint shaderProgram;
    
    // Buffer Objects
    GLuint vboId;
    
    BOOL initialized;
    int choosedBrustTexturteType;
}
@property (nonatomic, retain) NSMutableArray *vertexBuffers;
@property (nonatomic, retain) NSMutableArray *vertexBuffersPools;
@property (nonatomic, retain) NSMutableArray *pointTracker;
@end

@implementation PaintingView

@synthesize  location, brushScale, brushStep;
@synthesize  previousLocation, vertexBuffers;

// Implement this to override the default layer class (which is [CALayer class]).
// We do this so that our view will be backed by a layer that is capable of OpenGL ES rendering.
+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

// The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
	
    if ((self = [super initWithCoder:coder])) {
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = YES;
		// In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
			[self release];
			return nil;
		}
        
        // Set the view's scale factor as you wish
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
		// Make sure to start with a cleared buffer
		needsErase = YES;
	}
	
	return self;
}

// If our view is resized, we'll be asked to layout subviews.
// This is the perfect opportunity to also update the framebuffer so that it is
// the same size as our display area.
-(void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
    
    if (!initialized) {
        initialized = [self initGL];
    }
    else {
        [self resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
	
	// Clear the framebuffer the first time it is allocated
	if (needsErase) {
		[self erase];
		needsErase = NO;
	}
}

- (void)setupShaders
{
	for (int i = 0; i < NUM_PROGRAMS; i++)
	{
		char *vsrc = readFile(pathForResource(program[i].vert));
		char *fsrc = readFile(pathForResource(program[i].frag));
		GLsizei attribCt = 0;
		GLchar *attribUsed[NUM_ATTRIBS];
		GLint attrib[NUM_ATTRIBS];
		GLchar *attribName[NUM_ATTRIBS] = {
			"inVertex",
		};
		const GLchar *uniformName[NUM_UNIFORMS] = {
			"MVP", "pointSize", "vertexColor", "texture",
		};
		
		// auto-assign known attribs
		for (int j = 0; j < NUM_ATTRIBS; j++)
		{
			if (strstr(vsrc, attribName[j]))
			{
				attrib[attribCt] = j;
				attribUsed[attribCt++] = attribName[j];
			}
		}
		
		glueCreateProgram(vsrc, fsrc,
                          attribCt, (const GLchar **)&attribUsed[0], attrib,
                          NUM_UNIFORMS, &uniformName[0], program[i].uniform,
                          &program[i].id);
		free(vsrc);
		free(fsrc);
        
        // Set constant/initalize uniforms
        if (i == PROGRAM_POINT)
        {
            glUseProgram(program[PROGRAM_POINT].id);
            
            // the brush texture will be bound to texture unit 0
            glUniform1i(program[PROGRAM_POINT].uniform[UNIFORM_TEXTURE], 0);
            
            // viewing matrices
            GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
            GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
            GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
            
            glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
        
            // point size
            glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], brushTexture.width / brushScale);
            
            // initialize brush color
            glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
        }
	}
    
    glError();
}

- (UIImage *)changeBlackColorTransparent: (UIImage *)image
{
    CGImageRef rawImageRef=image.CGImage;
    
    const float colorMasking[6] = {0, 1, 0, 1, 0, 1};
    
    UIGraphicsBeginImageContext(image.size);
    CGImageRef maskedImageRef=CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        //if in iphone
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    }
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), maskedImageRef);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(maskedImageRef);
    UIGraphicsEndImageContext();
    return result;
}

// Create a texture from an image
- (textureInfo_t)textureFromName:(NSString *)name
{
    CGImageRef		brushImage;
	CGContextRef	brushContext;
	GLubyte			*brushData;
	size_t			width, height;
    GLuint          texId;
    textureInfo_t   texture;
    
    brushImage = [UIImage imageNamed:name].CGImage;
    
    // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
    //brushImage = [UIImage imageNamed:name].CGImage;
    
    // Get the width and height of the image
    width = CGImageGetWidth(brushImage);
    height = CGImageGetHeight(brushImage);
    
    // Make sure the image exists
    if(brushImage) {
        // Allocate  memory needed for the bitmap context
        brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
        // Use  the bitmatp creation function provided by the Core Graphics framework.
        brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
        // After you create the context, you can draw the  image to the context.
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
        // You don't need the context at this point, so you need to release it to avoid memory leaks.
        CGContextRelease(brushContext);
        // Use OpenGL ES to generate a name for the texture.
        glGenTextures(1, &texId);
        // Bind the texture name.
        glBindTexture(GL_TEXTURE_2D, texId);
        // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        // Specify a 2D texture image, providing the a pointer to the image data in memory
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
        // Release  the image data; it's no longer needed
        free(brushData);
        
        texture.id = texId;
        texture.width = width;
        texture.height = height;
    }
    
    return texture;
}

- (BOOL)initGL
{
    // Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffers(1, &viewFramebuffer);
	glGenRenderbuffers(1, &viewRenderbuffer);
	
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
	// For this sample, we do not need a depth buffer. If you do, this is how you can create one and attach it to the framebuffer:
//    glGenRenderbuffers(1, &depthRenderbuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
//    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		return NO;
	}
    
    // Setup the view port in Pixels
    glViewport(0, 0, backingWidth, backingHeight);
    
    // Create a Vertex Buffer Object to hold our data
    glGenBuffers(1, &vboId);
    
    // Load the brush texture
    [self setBgTextTure:0];
    
    // Load shaders
    [self setupShaders];
    
    // Enable blending and set a blending function appropriate for premultiplied alpha pixel data
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    // Playback recorded path, which is "Shake Me"
    NSMutableArray* recordedPaths = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Recording" ofType:@"data"]];
    if([recordedPaths count])
        [self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.2];
    
    return YES;
}

- (void)setBgTextTure:(int)type
{
    choosedBrustTexturteType = type;
    switch (type) {
        case 0:
            brushTexture = [self textureFromName:@"Eraser.png"];
            break;
        case 1:
            brushTexture = [self textureFromName:@"Pencil-Particle.png"];
            break;
        case 2:
            brushTexture = [self textureFromName:@"Eraser.png"];
            break;
        case 3:
            brushTexture = [self textureFromName:@"Eraser.png"];
            break;
        case 4:
            brushTexture = [self textureFromName:@"Kuas.png"];
            break;
            
        default:
            break;
    }
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
	// Allocate color buffer backing based on the current layer size
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
    // For this sample, we do not need a depth buffer. If you do, this is how you can allocate depth buffer backing:
//    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
//    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    // Update projection matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    glUseProgram(program[PROGRAM_POINT].id);
    glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    
    // Update viewport
    glViewport(0, 0, backingWidth, backingHeight);
	
    return YES;
}

// Releases resources when they are not longer needed.
- (void)dealloc
{
    // Destroy framebuffers and renderbuffers
	if (viewFramebuffer) {
        glDeleteFramebuffers(1, &viewFramebuffer);
        viewFramebuffer = 0;
    }
    if (viewRenderbuffer) {
        glDeleteRenderbuffers(1, &viewRenderbuffer);
        viewRenderbuffer = 0;
    }
	if (depthRenderbuffer)
	{
		glDeleteRenderbuffers(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
    // texture
    if (brushTexture.id) {
		glDeleteTextures(1, &brushTexture.id);
		brushTexture.id = 0;
	}
    // vbo
    if (vboId) {
        glDeleteBuffers(1, &vboId);
        vboId = 0;
    }
    
    // tear down context
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	
	[context release];
    
	[super dealloc];
}

// Erases the screen
- (void)erase
{
    [self.vertexBuffersPools removeAllObjects];
	[EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
    
	// Display the buffer
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
}

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	static GLfloat*		vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger			vertexCount = 0,
						count,
						i;
	
	[EAGLContext setCurrentContext:context];
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	
	// Convert locations from Points to Pixels
	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
	
	// Allocate vertex array buffer
	if(vertexBuffer == NULL)
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
	
	// Add points to the buffer so there are drawing points every X pixels
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / brushStep), 1);
	for(i = 0; i < count; ++i) {
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
    
	// Load data to the Vertex Buffer Object
	glBindBuffer(GL_ARRAY_BUFFER, vboId);
	glBufferData(GL_ARRAY_BUFFER, vertexCount*2*sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
	
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);
	
	// Draw
    glUseProgram(program[PROGRAM_POINT].id);
	glDrawArrays(GL_POINTS, 0, vertexCount);
    
	// Display the buffer
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
    
    // Store VBO for undo
    NSData *data = [NSData dataWithBytes:vertexBuffer length:vertexCount * sizeof(GLfloat) * 2] ;
    if (self.vertexBuffers == nil) self.vertexBuffers = [[NSMutableArray alloc] init];
    [self.vertexBuffers addObject:data];
}

// Reads previously recorded points and draws them onscreen. This is the Shake Me message that appears when the application launches.
- (void)playback:(NSMutableArray*)recordedPaths
{
	NSData*				data = [recordedPaths objectAtIndex:0];
	CGPoint*			point = (CGPoint*)[data bytes];
	NSUInteger			count = [data length] / sizeof(CGPoint),
						i;
	
	// Render the current path
	for(i = 0; i < count - 1; ++i, ++point)
		[self renderLineFromPoint:*point toPoint:*(point + 1)];
	
	// Render the next path after a short delay 
	[recordedPaths removeObjectAtIndex:0];
	if([recordedPaths count])
		[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.01];
}


// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	firstTouch = YES;
	// Convert touch point from UIView referential to OpenGL one (upside-down flip)
	location = [touch locationInView:self];
	location.y = bounds.size.height - location.y;
    self.pointTracker = nil;
    self.pointTracker = [[NSMutableArray alloc] init];
    [self.pointTracker addObject:[NSValue valueWithCGPoint:location]];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{   
	CGRect				bounds = [self bounds];
	UITouch*			touch = [[event touchesForView:self] anyObject];
		
	// Convert touch point from UIView referential to OpenGL one (upside-down flip)
	if (firstTouch) {
		firstTouch = NO;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
	} else {
		location = [touch locationInView:self];
	    location.y = bounds.size.height - location.y;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
        
        [self.pointTracker addObject:[NSValue valueWithCGPoint:location]];
        // Render the stroke
        [self renderLineFromPoint:previousLocation toPoint:location];
	}
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	if (firstTouch) {
		firstTouch = NO;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
		[self renderLineFromPoint:previousLocation toPoint:location];
	}
    
    [self.pointTracker addObject:[NSValue valueWithCGPoint:location]];
    
    if (self.vertexBuffersPools == nil) self.vertexBuffersPools = [[NSMutableArray alloc] init];
    
    float red = brushColor[0];
    float green = brushColor[1];
    float blue = brushColor[2];
    float alpha = brushColor[3];
    
    NSArray *arrayProperties = [[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:red], [NSNumber numberWithFloat:green], [NSNumber numberWithFloat:blue], [NSNumber numberWithFloat:alpha], [NSNumber numberWithInt:choosedBrustTexturteType], [NSNumber numberWithFloat:brushScale], [NSNumber numberWithFloat:brushStep], [NSArray arrayWithArray:self.vertexBuffers], nil];
    
    [self.vertexBuffersPools addObject:arrayProperties];
    [self.vertexBuffers removeAllObjects];
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If appropriate, add code necessary to save the state of the application.
	// This application is not saving state.
}

- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
    [self setBrushColorWithRed:red green:green blue:blue alpha:1];
}

- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
    [self setupShaders];
	// Update the brush color
    brushColor[0] = red;
    brushColor[1] = green;
    brushColor[2] = blue;
    brushColor[3] = alpha;
    
    if (initialized) {
        glUseProgram(program[PROGRAM_POINT].id);
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
    }
}

- (void)undo
{
    [EAGLContext setCurrentContext:context];
    
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
    
    // Render remaining vbos
    [self.vertexBuffersPools removeLastObject];
    CGFloat lastBrush[4];
    lastBrush[0] = brushColor[0];
    lastBrush[1] = brushColor[1];
    lastBrush[2] = brushColor[2];
    lastBrush[3] = brushColor[3];
    
    CGFloat lastBrushScale = brushScale;
    CGFloat lastBrushStep = brushStep;
    
    int lastBgTexture = choosedBrustTexturteType;
    
    for (NSArray *array in self.vertexBuffersPools) {
        CGFloat tempBrush[4];
        tempBrush[0] = [[array objectAtIndex:0] floatValue];
        tempBrush[1] = [[array objectAtIndex:1] floatValue];
        tempBrush[2] = [[array objectAtIndex:2] floatValue];
        tempBrush[3] = [[array objectAtIndex:3] floatValue];
        
        NSLog(@"Last brush scale : %f, brush step : %f", brushScale, brushStep);
        
        /*[self setBrushScale:[[array objectAtIndex:4] floatValue]];
        [self setBrushStep:[[array objectAtIndex:5] floatValue]];
        
        NSLog(@"Temp brush scale : %f, brush step : %f", brushScale, brushStep);*/
        
        [self setBrushColorWithRed:tempBrush[0] green:tempBrush[1] blue:tempBrush[2] alpha:tempBrush[3]];
        //[self setBgTextTure:[[array objectAtIndex:4] integerValue]];
        
        for (NSData *vbo in [array objectAtIndex:7])
        {
            // Load data to the Vertex Buffer Object
            glBindBuffer(GL_ARRAY_BUFFER, vboId);
            glBufferData(GL_ARRAY_BUFFER, vbo.length, vbo.bytes, GL_DYNAMIC_DRAW);
            
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);
            
            // Draw
            glUseProgram(program[PROGRAM_POINT].id);
            glDrawArrays(GL_POINTS, 0, [vbo length] / sizeof(CGPoint));
        }
    }
    
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    
    //[self setBrushScale:lastBrushScale];
    //[self setBrushStep:lastBrushStep];
    [self setBrushColorWithRed:lastBrush[0] green:lastBrush[1] blue:lastBrush[2] alpha:lastBrush[3]];
    //[self setBgTextTure:lastBgTexture];
}

- (UIImage *) glToUIImage
{
    CGSize frame = self.frame.size;
    int imageWidth = (int)frame.width;
    int imageHeight = (int)frame.height;
    
    NSInteger myDataLength = imageWidth * imageHeight * 4;
    
    
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, imageWidth, imageHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    
    GLubyte R, G, B, A;
    
    for(int y = 0; y < imageHeight; y++){
        for(int x = 0; x < imageWidth*4; x+=4){
            R = buffer[y * 4 * imageWidth + x];
            G = buffer[y * 4 * imageWidth + x +1];
            B = buffer[y * 4 * imageWidth + x +2];
            A = buffer[y * 4 * imageWidth + x +3];
            
            buffer2[((imageHeight - 1) - y) * imageWidth * 4 + x]    = 255-(A-R);
            buffer2[((imageHeight - 1) - y) * imageWidth * 4 + x +1] = 255-(A-G);
            buffer2[((imageHeight - 1) - y) * imageWidth * 4 + x +2] = 255-(A-B);
            
            buffer2[((imageHeight - 1) - y) * imageWidth * 4 + x +3] = 255;
        }
    }
    
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
    //CGDataProviderRef provider2 = CGDataProviderCreateWithData(NULL, white, myDataLength, NULL);
    
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * imageWidth;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    
    CGDataProviderRelease(provider);
    
    free(buffer);
    free(buffer2);
    
    return myImage;
}

@end
