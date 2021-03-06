//
//  FightViewController.m
//  VirtualPet
//
//  Created by Ezequiel on 12/12/14.
//  Copyright (c) 2014 Ezequiel. All rights reserved.
//

#import "FightViewController.h"
#import "NSTimer+TimerWithAutoInvalidate.h"
#import "MyPet.h"

@interface FightViewController ()

@property (nonatomic) float maxPower;
@property (nonatomic) int contador;
@property (atomic) bool hitting;
@property (nonatomic, strong) Pet* enemyPet;

@end

@implementation FightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.hitting = NO;
    self.contador = 0;
    
    [self setUpUI];
    [self setUpMultipeer];
    //[self reloadViewData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MyPet sharedInstance].health = 1000;
    
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self.motionManager stopAccelerometerUpdates];
    
    [super viewDidDisappear:animated];
}

- (void) reloadViewData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.healthEnemy setText:[NSString stringWithFormat:@"%d / 1000", self.enemyPet.health]];
        [self.nameEnemy setText:[NSString stringWithFormat:@"%@", self.enemyPet.petName]];
        [self.imgEnemy setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.enemyPet.petImageName]]];
        
        self.healthMine.text = [NSString stringWithFormat:@"%d / 1000", [MyPet sharedInstance].health];
        self.nameMine.text = [MyPet sharedInstance].petName;
        self.imgMine.image = [UIImage imageNamed:[MyPet sharedInstance].petImageName];
    });
}

//**************************************************
// Conectivity
//**************************************************

- (void) setUpMultipeer{
    //  Setup peer ID
    self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[MyPet sharedInstance].petName];
    
    //  Setup session
    self.mySession = [[MCSession alloc] initWithPeer:self.myPeerID];
    self.mySession.delegate = self;
    
    //  Setup BrowserViewController
    self.browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"chat" session:self.mySession];
    self.browserVC.delegate = self;
    
    //  Setup Advertiser
    self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"chat" discoveryInfo:nil session:self.mySession];
    [self.advertiser start];
}

- (void) setUpUI{
    //  Setup the browse button
    [self.browserButton addTarget:self action:@selector(showBrowserVC) forControlEvents:UIControlEventTouchUpInside];
    
    //  Setup TextBox
    self.textBox.editable = NO;
    self.textBox.backgroundColor = [UIColor whiteColor];
    
    //  Setup ChatBox
    self.chatBox.backgroundColor = [UIColor lightGrayColor];
    self.chatBox.returnKeyType = UIReturnKeySend;
    self.chatBox.delegate = self;
}

- (void) showBrowserVC{
    [self presentViewController:self.browserVC animated:YES completion:nil];
}

#pragma marks MCBrowserViewControllerDelegate

// Notifies the delegate, when the user taps the done button
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [self.browserVC dismissViewControllerAnimated:YES completion:nil];
    [self sendText:@"Connected"];
    [self checkAccelerometer];
    [self.chatBox setEnabled:NO];
    [self sendData:[NSNumber numberWithInt:0]];
}

// Notifies delegate that the user taps the cancel button.
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [self.browserVC dismissViewControllerAnimated:YES completion:nil];
}

//***********************
// Sending Data
//***********************

- (void) sendData :(NSNumber*) attkPower{
    NSString *name = [MyPet sharedInstance].petName;
    NSString *image = [MyPet sharedInstance].petImageName;
    NSNumber* health = [NSNumber numberWithInt:[MyPet sharedInstance].health];
    NSNumber* hit = attkPower;
    
    NSDictionary* dic = @{@"name" : name,
                          @"image" : image,
                          @"health" : health,
                          @"hit" : hit};
    
    //  Convert text to NSData
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dic];
    
    //  Send data to connected peers
    NSError *error;
    [self.mySession sendData:data toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
    
    //  Append your own text to text box
    [self reloadViewData];
}

- (void) sendText: (NSString*) text
{
    NSString *message = text;
    self.chatBox.text = @"";
    
    NSDictionary *dic = @{@"message" : message};
    
    //  Convert text to NSData
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dic];
    
    //  Send data to connected peers
    NSError *error;
    [self.mySession sendData:data toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
    
    //  Append your own text to text box
    [self receiveMessage: message fromPeer: self.myPeerID];
}

- (void) receiveMessage: (NSString *) message fromPeer: (MCPeerID *) peer{
    //  Create the final text to append
    NSString *finalText;
    if (peer == self.myPeerID) {
        finalText = [NSString stringWithFormat:@"-Me: %@\r\n", message];
    }
    else{
        finalText = [NSString stringWithFormat:@"-%@: %@\r\n", peer.displayName, message];
    }
    
    //  Append text to text box
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textBox.text = [self.textBox.text stringByAppendingString:finalText];
        [self.textBox scrollRangeToVisible:NSMakeRange([self.textBox.text length], 0)];
    });
    
}

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    
}

// Received data from remote peer ******* Vamos a usar este *********
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    
    NSDictionary* dic = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if([dic objectForKey:@"message"])
    {
        //  Decode data back to NSString
        NSString *message = (NSString*)[dic objectForKey:@"message"];
        if([message isEqualToString:@"Connected"])
        {
            [self.chatBox setEnabled:NO];
            [self checkAccelerometer];
        }
        
        //  append message to text box on main thread
        dispatch_async(dispatch_get_main_queue(),^{
            [self receiveMessage: message fromPeer: peerID];
        });
    }
    else
    {
        if(![peerID isEqual:self.myPeerID])
        {
            if(self.enemyPet)
            {
                self.enemyPet.health = ((NSNumber*)[dic objectForKey:@"health"]).intValue;
            }
            else
            {
                self.enemyPet = [[Pet alloc] initWithDictionaryForFight:dic];
                [self sendData:[NSNumber numberWithInt:0]];
            }
            [MyPet sharedInstance].health -= ((NSString*)[dic objectForKey:@"hit"]).intValue;
            if([MyPet sharedInstance].health <= 0)
            {
                [MyPet sharedInstance].health = 0;
                [self sendText:[NSString stringWithFormat:@"%@ has been defeated", [MyPet sharedInstance].petName]];
                ////////////////////////////////// Sonido de Derrota //////////////////////////////////
                
                ///////////////////////////////////////////////////////////////////////////////////////
                [self.motionManager stopAccelerometerUpdates];
                [self.chatBox setEnabled:YES];
            }
            [self reloadViewData];
        }
    }
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
}

//********************
// Text Field Delegate
//********************

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    [self sendText:self.chatBox.text];
    return YES;
}

//**************************************************
// Accelerometer
//**************************************************

- (void) checkAccelerometer
{
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData* accelerometer, NSError* error){
       
        //NSLog(@"X: %f", accelerometer.acceleration.x); // -> Derecha + <- Izquierda -
        //NSLog(@"Y: %f", accelerometer.acceleration.y); // Siempre Positivo
        //NSLog(@"Z: %f", accelerometer.acceleration.z); // Siempre Positivo
        
        float power = 0.0;

        if(accelerometer.acceleration.x > 4)
        {
            power = accelerometer.acceleration.x;
        }
        if(accelerometer.acceleration.y > 4 && accelerometer.acceleration.y > power)
        {
            power = accelerometer.acceleration.y;
        }
        if(accelerometer.acceleration.z > 4 && accelerometer.acceleration.z > power)
        {
            power = accelerometer.acceleration.z;
        }
        
        if(self.maxPower < power && !self.hitting)
        {
            self.maxPower = power;
            [self.motionManager stopAccelerometerUpdates];
            self.hitting = YES;
            [self hitEnemyPet: power];
            return;
        }
    }];
}

- (void) hitEnemyPet: (int) power
{
    NSLog(@"Critish: %f", self.maxPower);
    self.contador = 0;
    self.maxPower = 0.0f;
    self.hitting = NO;
    
    int hitPower = power * 3;
    [self sendData:[NSNumber numberWithInt:hitPower]];
    self.enemyPet.health -= hitPower;
    //[self sendText:[NSString stringWithFormat:@"%d", hitPower]];
    
    if(self.enemyPet.health <= 0)
    {
        self.enemyPet.health = 0;
        [self sendText:[NSString stringWithFormat:@"%@ Win the Fight!!!!!", [MyPet sharedInstance].petName]];
        [self.chatBox setEnabled:YES];
        /////////////////////////////////// Sonido de Victoria /////////////////////////////////////
        
        ////////////////////////////////////////////////////////////////////////////////////////////
    }
    else
    {
        [self checkAccelerometer];
    }
    [self reloadViewData];
    
    ////////////////////////////// Sonido de Golpe Aca ////////////////////////////////////
    
    ///////////////////////////////////////////////////////////////////////////////////////
}

@end
