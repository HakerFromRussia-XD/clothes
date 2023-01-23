/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller and cross-platform view that displays OpenGL content.
*/
#import "AAPLOpenGLViewController.h"
#import "AAPLOpenGLRenderer.h"
//#import "MotoricaStart-Swift.h"

#import <UIKit/UIKit.h>
#define PlatformGLContext EAGLContext


@implementation AAPLOpenGLView

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

@end

@implementation AAPLOpenGLViewController
{
    AAPLOpenGLView *_view;
    AAPLOpenGLRenderer *_openGLRenderer;
//    GestureSettingsViewController *gestureVC;
//    SensorsViewController *sensorsVC;
//    SampleGattAttributes *sampleGattAtributes;
    PlatformGLContext *_context;
    GLuint _defaultFBOName;
    
    GLuint _colorRenderbuffer;
    GLuint _depthRenderbuffer;
    CADisplayLink *_displayLink;
    __weak IBOutlet UIButton *state_btn;
    __weak IBOutlet UIButton *fingers_delay_btn;
    __weak IBOutlet UILabel *deviceName;
    __weak IBOutlet UIImageView *statusConnection;
    UIImage *connectStatus;
    UIImage *disconnectStatus;
    
    NSInteger _typeMultigribNewVM;
    NSInteger _gestureNumber;
    NSInteger _gestureTable[84];
    NSString *_gestureTableStr;
    float _previousX;
    float _previousY;
    bool _stop;
    bool state;
    
    int openStage1;
    int openStage2;
    int openStage3;
    int openStage4;
    int openStage5;
    int openStage6;
    
    int closeStage1;
    int closeStage2;
    int closeStage3;
    int closeStage4;
    int closeStage5;
    int closeStage6;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear");
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Отсюда мы начинаем исполнение программы");
//    gestureVC = [[GestureSettingsViewController alloc]init];
//    sensorsVC = [[SensorsViewController alloc]init];
//    sampleGattAtributes = [[SampleGattAttributes alloc]init];
    UIImage *connectStatus = [UIImage imageNamed: @"connect_status.png"];
    UIImage *disconnectStatus = [UIImage imageNamed: @"disconnect_status.png"];
//    deviceName.text = [gestureVC getDeviceName];
//    [gestureVC savingDeviceName];
//    if ([gestureVC getStatusConnection] == 1) {
//        statusConnection.image = connectStatus;
//    } else {
//        statusConnection.image = disconnectStatus;
//    }
    [self stylizationStateBtn];
    openStage1 = 0;
    openStage2 = 0;
    openStage3 = 0;
    openStage4 = 0;
    openStage5 = 0;
    openStage6 = 0;
    closeStage1 = 0;
    closeStage2 = 0;
    closeStage3 = 0;
    closeStage4 = 0;
    closeStage5 = 0;
    closeStage6 = 0;
    
//    _gestureNumber = [gestureVC getGestureNum];
//    _gestureTableStr = [gestureVC getGestureTable];
//    _typeMultigribNewVM = [gestureVC getUseFestX];
    
    
    state = 0;

    _stop = false;
    _previousX = 0.0f;
    _previousY = 0.0f;
    
    _view = (AAPLOpenGLView *)self.view;
    
    [self prepareView];

    [self makeCurrentContext];

    _openGLRenderer = [[AAPLOpenGLRenderer alloc] initWithDefaultFBOName:_defaultFBOName];

    if(!_openGLRenderer)
    {
        NSLog(@"OpenGL renderer failed initialization.");
        return;
    }

    [_openGLRenderer resize:self.drawableSize];
    
    // Расчёт коэффициентов для верного пересчёта координат пальца на экране в координаты эекрана OpenGL
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    NSLog(@"Размер экрана   screenWidth: %f   screenHeight: %f", screenWidth, screenHeight);
    [_openGLRenderer calculationOfCoefficients:screenWidth :screenHeight];
    
    [_openGLRenderer saveStateData: @"0"];
}



- (IBAction)unwindToOpenGLVC:(UIStoryboardSegue *)segue {
    
}

- (IBAction)perehod:(UIButton *)sender {
    _stop = true;
    // возобновляем работу протеза от датчиков
    uint8_t data[]   = { 0x01 };
    if (_typeMultigribNewVM) {
//        [self sendDataToFest:data :sampleGattAtributes.SENS_ENABLED_NEW_VM :sizeof(data)];
    } else {
//        [self sendDataToFest:data :sampleGattAtributes.SENS_ENABLED_NEW :sizeof(data)];
    }
    
    [_openGLRenderer stopVC];
}

- (IBAction)chageState:(UIButton *)sender {
    if (state == 0 ) {
        state = 1;
        [state_btn setTitle:@"close state" forState:UIControlStateNormal];
        [_openGLRenderer changeState:state];
//        - (void)changeState :(BOOL) state
//        return state;
    } else {
        state = 0;
        [state_btn setTitle:@"open state" forState:UIControlStateNormal];
        [_openGLRenderer changeState:state];
//        return state;
    }
}

- (IBAction)openFingersDealyDialog:(UIButton *)sender {
    [_openGLRenderer savesAllData];
}

- (void)stylizationStateBtn {
    state_btn.layer.cornerRadius = 21;
    state_btn.layer.borderWidth = 2;
    state_btn.layer.borderColor = UIColor.whiteColor.CGColor;
}

- (void)prepareView
{
    NSLog(@"1 - Подготавливаем вью");
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.view.layer;

    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @NO,
                                     kEAGLDrawablePropertyColorFormat     : kEAGLColorFormatSRGBA8 };
    eaglLayer.opaque = YES;
    

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!_context || ![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Could not create an OpenGL ES context.");
        return;
    }

    [self makeCurrentContext];

    self.view.contentScaleFactor = [UIScreen mainScreen].nativeScale;

    // In iOS & tvOS, you must create an FBO and attach a drawable texture allocated by
    // Core Animation to use as the default FBO for a view.
    glGenFramebuffers(1, &_defaultFBOName);
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFBOName);

    glGenRenderbuffers(1, &_colorRenderbuffer);

    glGenRenderbuffers(1, &_depthRenderbuffer);

    [self resizeDrawable];

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);

    // Create the display link so you render at 60 frames per second (FPS).
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(draw:)];

    _displayLink.preferredFramesPerSecond = 60;

    // Set the display link to run on the default run loop (and the main thread).
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
//    if ([gestureVC getFingersDelaySwitch] && [gestureVC getUseFestX]) {
//        [fingers_delay_btn setAlpha:1];
//    } else { [fingers_delay_btn setAlpha:0]; }
    
}

- (void)makeCurrentContext
{
    NSLog(@"2 - Создаём контекст этого вью");
    [EAGLContext setCurrentContext:_context];
}

- (CGSize)drawableSize
{
    GLint backingWidth, backingHeight;
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    CGSize drawableSize = {backingWidth, backingHeight};
    NSLog(@"3 - Подгонка размера вью под размер экрана backingWidth: %d  backingHeight: %d", backingWidth, backingHeight);
    return drawableSize;
}

- (void)resizeDrawable
{
    [self makeCurrentContext];

    // First, ensure that you have a render buffer.
    assert(_colorRenderbuffer != 0);

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)_view.layer];

    CGSize drawableSize = self.drawableSize;

    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, drawableSize.width, drawableSize.height);

    GetGLError();

    [_openGLRenderer resize:self.drawableSize];
}

- (void)draw:(id)sender
{
    if (!_stop) {
        [EAGLContext setCurrentContext:_context];
            [_openGLRenderer draw];

            glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
            [_context presentRenderbuffer:GL_RENDERBUFFER];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint newCoords = [touch locationInView:self.view];
    [_openGLRenderer touchIvent:newCoords.x :newCoords.y :0 :0];
    [_openGLRenderer beginTouchIvent];
    _previousX = newCoords.x;
    _previousY = newCoords.y;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint newCoords = [touch locationInView:self.view];
    float deltaX = (newCoords.x - _previousX) / 6.0f;
    float deltaY = (newCoords.y - _previousY) / 6.0f;
    
    [_openGLRenderer touchIvent:newCoords.x :newCoords.y :deltaX :deltaY];
    
    _previousX = newCoords.x;
    _previousY = newCoords.y;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_openGLRenderer endTouchIvent];
}

- (void)sendDataToFest :(uint8_t*) dataForWrite :(NSString*) characteristic  :(NSInteger) lenght {
    NSData *nsdataObj = [NSData dataWithBytes:dataForWrite length:lenght];
    if (_typeMultigribNewVM) {
//        [gestureVC sendDataToFestWithDataForWrite:nsdataObj characteristic:characteristic typeFestX:true];
    } else{
//        [gestureVC sendDataToFestWithDataForWrite:nsdataObj characteristic:characteristic typeFestX:false];
        
    }
}

@end
