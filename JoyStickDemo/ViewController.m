//
//  ViewController.m
//  JoyStickDemo
//
//  Created by teejay on 5/14/13.
//  Copyright (c) 2013 teejay. All rights reserved.
//


#import "ViewController.h"

#import "MFLJoystick.h"
#import "JoystickDemo-Swift.h"

@interface ViewController () <JoystickDelegate, MFLSwiftJoystickDelegate>

@property dispatch_source_t     _timer;

@property (weak) IBOutlet UIView *playerObjC;
@property (weak) IBOutlet UIView *playerSwift;

@property (weak) IBOutlet MFLJoystick *objcJoystick;
@property (weak) IBOutlet MFLSwiftJoystickImplementation *swiftJoystick;
@property (weak, nonatomic) IBOutlet UIButton *accelerateButton;
@property (weak, nonatomic) IBOutlet UIButton *decelerateButton;
@property (weak, nonatomic) IBOutlet UIButton *accelerationLabel;
@property (weak, nonatomic) IBOutlet UIButton *angleLabel;
@property (weak, nonatomic) IBOutlet UIButton *radiusLabel;
@property CGPoint playerObjCOrigin;
@property CGPoint playerSwiftOrigin;

// control tuning parameters
@property float timeoutInSeconds;
@property float accelerationIncrementPerTimeout;

// control inputs
@property float acceleration;
@property float angle;
@property float radius;


// communication
@property WebSocket* _webSocket;
//@property MyWebSocket* _mwebsocket;

@end

@implementation ViewController

- (void) updateLabels {
    NSString *s = [NSString stringWithFormat:@"Acceleration: %.2f",self.acceleration];
    [self.accelerationLabel setTitle:s forState:UIControlStateNormal];
    
    NSString *s2 = [NSString stringWithFormat:@"Angle: %.2f",self.angle];
    [self.angleLabel setTitle:s2 forState:UIControlStateNormal];
    
    NSString *s3 = [NSString stringWithFormat:@"Radius: %.2f",self.radius];
    [self.radiusLabel setTitle:s3 forState:UIControlStateNormal];
    
//    [self._mwebsocket echoTest];
    NSString *msg = [NSString stringWithFormat:@"%.2f %.2f",self.acceleration,self.angle];
    NSLog(@"acceleration, steering");
    [self._webSocket sendWithText:msg];
}

- (void)incrementAcceleration:(float)inc{
    self.acceleration += inc;
    if (self.acceleration > 1.0) {
        self.acceleration = 1.0;
    } else if (self.acceleration < -1.0) {
        self.acceleration = -1.0;
    }
    [self updateLabels];
}

- (void)loopIncrementAcceleration:(float)inc{
    if (!self._timer) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        self._timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        // This is the number of seconds between each firing of the timer
        dispatch_source_set_timer(
                                  self._timer,
                                  dispatch_time(DISPATCH_TIME_NOW, self.timeoutInSeconds * NSEC_PER_SEC),
                                  self.timeoutInSeconds * NSEC_PER_SEC,
                                  0.10 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self._timer, ^{
            // ***** LOOK HERE *****
            // This block will execute every time the timer fires.
            // Do any non-UI related work here so as not to block the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                // Do UI work on main thread
                if (inc>0){
                    NSLog(@"Look, Mom, I'm accelerating");
                } else {
                    NSLog(@"Look, Mom, I'm decelerating");
                }
                [self incrementAcceleration:inc];
            });
        });
    }
    
    dispatch_resume(self._timer);
}

- (IBAction)stopAccChange:(id)sender {
    NSLog(@"Look, Mom, I'm stopping");
    if (self._timer) {
        dispatch_source_cancel(self._timer);
        self._timer = nil;
        self.acceleration = 0.0;
    }
    [self updateLabels];
}

- (IBAction)accDown:(id)sender {
    [self loopIncrementAcceleration:self.accelerationIncrementPerTimeout];
}

- (IBAction)decDown:(id)sender {
    [self loopIncrementAcceleration:(-1.0*self.accelerationIncrementPerTimeout)];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Set y depend on interface orientation
    CGFloat originInY = ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)  ? 105.0f : 35.0f);
     
     // Set the button's y offset
     [self.accelerateButton setFrame:CGRectMake(self.accelerateButton.frame.origin.x, originInY, self.accelerateButton.frame.size.width, self.accelerateButton.frame.size.height)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self.accelerateButton setFrame:CGRectMake(self.view.frame.size.width-self.accelerateButton.frame.size.width-20, self.view.frame.size.height-self.accelerateButton.frame.size.height-40, self.accelerateButton.frame.size.width, self.accelerateButton.frame.size.height)];
//    
//    [self.decelerateButton setFrame:CGRectMake(self.view.frame.size.width-self.decelerateButton.frame.size.width-40, self.view.frame.size.height-self.decelerateButton.frame.size.height-120, self.decelerateButton.frame.size.width, self.decelerateButton.frame.size.height)];
//    [self.decelerateButton setCenter:CGPoint(,0)]
    
    self.playerObjCOrigin = self.playerObjC.frame.origin;
        self.playerSwiftOrigin = self.playerSwift.frame.origin;

    [self.objcJoystick setThumbImage:[UIImage imageNamed:@"joy_thumb.png"]
                          andBGImage:[UIImage imageNamed:@"stick_base.png"]];

    [self.swiftJoystick setupWithThumbAndBackgroundImages:[UIImage imageNamed:@"joy_thumb.png"]
                                                  bgImage:[UIImage imageNamed:@"stick_base.png"]];
    [self.swiftJoystick setDelegate:self];
    
    self.acceleration = 0.0;
    self.timeoutInSeconds = 0.10;
    self.accelerationIncrementPerTimeout = 0.1;
    
    self._webSocket = [[WebSocket alloc] init:@"ws://53.255.105.66:9002"];
//    self._webSocket.delegate = self;
    [self._webSocket open];
    NSAssert(self._webSocket.readyState == WebSocketReadyStateConnecting, @"WebSocket is not connecting");
    
//    [[[Connection alloc] init] open];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// update when ObjC joystick has moved
- (void)joystick:(MFLJoystick *)aJoystick didUpdate:(CGPoint)dir
{
    CGPoint newpos = self.playerObjCOrigin;
    newpos.x = 30.0 * dir.x + newpos.x;
    newpos.y = 30.0 * dir.y + newpos.y;
    CGRect fr = self.playerObjC.frame;
    fr.origin = newpos;
    self.playerObjC.frame = fr; // updates frame position
    
    [self updateLabels];
}

// update when Swift joystick has moved
- (void)joyStickDidUpdate:(CGPoint)movement
{
//    CGPoint newpos = self.playerSwiftOrigin;
//    newpos.x = 30.0 * movement.x + newpos.x;
//    newpos.y = 30.0 * movement.y + newpos.y;
//    CGRect fr = self.playerSwift.frame;
//    fr.origin = newpos;
//    self.playerSwift.frame = fr;
    
//    self.radius = [self.swiftJoystick getRadius]/30.0;
//    self.angle = [self.swiftJoystick getAngle];
    [self setRadiusFromMovement:movement];
    [self setAngleFromMovement:movement];
    
    [self updateLabels];
}

- (void)setRadiusFromMovement:(CGPoint)movement
{
    self.radius = sqrt(movement.x*movement.x+movement.y*movement.y);
}

- (void)setAngleFromMovement:(CGPoint)movement
{
    if (movement.x < 0.000001 && movement.x > -0.000001){
        self.angle =  0.0;
    } else {
        self.angle = atan2(movement.x,fabs(movement.y));
    }
}

@end
