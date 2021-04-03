//
//  ConnectionController.m
//  DroneClient
//
//  Created by Ben Choi on 2/24/21.
//

#import "ConnectionController.h"
#import "DJIUtils.h"
#import "Constants.h"
#import "DroneComms.hpp"

@interface ConnectionController ()<DJISDKManagerDelegate, DJICameraDelegate, DJIBatteryDelegate, DJIBatteryAggregationDelegate, DJIFlightControllerDelegate, DJIVideoFeedListener, NSStreamDelegate>

@end

@implementation ConnectionController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self configureConnectionToProduct];
//    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0,0,1280,720)];
    [[DJIVideoPreviewer instance] setView:self.fpvPreviewView];
    NSLog(@"debug: width %f", self.fpvPreviewView.frame.size.width);
    NSLog(@"debug: height %f", self.fpvPreviewView.frame.size.height);
//    [[DJIVideoPreviewer instance] setView:newView];
//    [self.fpvPreviewView addSubview:newView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[DJIVideoPreviewer instance] setView:nil];
//    [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self connectToServer];
}

#pragma mark TCP Connection

- (void) sendMessage:(NSString *)message {
    NSLog(@"SKDLJFKDSJFLSDF");
    _serverConnectionStatusLabel.text = @"Server Status: Writing...";
    NSString *response  = [NSString stringWithFormat:@"%@", message];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    const unsigned  char *bytes= (const unsigned  char *)(data.bytes);
    [outputStream write:bytes maxLength:[data length]];
    _serverConnectionStatusLabel.text = @"Server Status: Connected";
}

- (void) sendPacket_CoreTelemetry {
    DroneInterface::Packet_CoreTelemetry packet_core;
    DroneInterface::Packet packet;
    
//    packet_core.isFlying = self->_isFlying;
//    packet_core.Latitude = self->_Latitude;
//    packet_core.Longitude = self->_Longitude;
//    packet_core.Altitude = self->_Altitude;
//    packet_core.HAG = self->_HAG;
//    packet_core.V_N = self->_velocity_n;
//    packet_core.V_N = self->_velocity_e;
//    packet_core.V_D = self->_velocity_d;
//    packet_core.Yaw = self->_yaw;
//    packet_core.Pitch = self->_pitch;
//    packet_core.Roll = self->_roll;
    
    packet_core.IsFlying = 1;
    packet_core.Latitude = 40.34555;
    packet_core.Longitude = 123.3333333;
    packet_core.Altitude = 1233;
    packet_core.HAG = 123;
    packet_core.V_N = 123.4;
    packet_core.V_N = 11.11123;
    packet_core.V_D = 333;
    packet_core.Yaw = 11;
    packet_core.Pitch = 0;
    packet_core.Roll = -23.4;
    
    packet_core.Serialize(packet);
    
//    NSString *response  = [NSString stringWithFormat:@"%@", message];
//    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
//    unsigned char* bytes;
//    unsigned int length;
//    packet.GetCharBuffer(bytes, length);
    NSData *data = [[NSData alloc] initWithBytesNoCopy:packet.m_data.data() length:packet.m_data.size() freeWhenDone:false];
    const unsigned char *bytes= (const unsigned char *)(data.bytes);
    [outputStream write:bytes maxLength:[data length]];
}

- (IBAction)sendDebugMessage:(id)sender {
//    [self sendMessage:TEST_MESSAGE];
    [self sendPacket_CoreTelemetry];
}

- (void) messageReceived:(NSString *)message {
    [messages addObject:message];
    NSLog(@"%@", message);
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {

    NSLog(@"stream event %lu", streamEvent);

    switch (streamEvent) {

        case NSStreamEventOpenCompleted: {
            NSLog(@"Stream opened");
            _serverConnectionStatusLabel.text = @"Server Status: Connected";
            break;
        }
        case NSStreamEventHasBytesAvailable:
            _serverConnectionStatusLabel.text = @"Server Status: Reading from server";
            if (theStream == inputStream)
            {
                uint8_t buffer[1024];
                NSInteger len;

                while ([inputStream hasBytesAvailable])
                {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];

                        if (nil != output)
                        {
                            _serverConnectionStatusLabel.text = @"Server Status: Connected";
                            NSLog(@"server said: %@", output);
                            [self messageReceived:output];
                        }
                    }
                }
            }
            break;

        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Stream has space available now");
            break;

        case NSStreamEventErrorOccurred:
             NSLog(@"%@",[theStream streamError].localizedDescription);
            break;

        case NSStreamEventEndEncountered:

            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            _serverConnectionStatusLabel.text = @"Server Status: Not Connected";
            NSLog(@"close stream");
            break;
        default:
            NSLog(@"Unknown event");
    }

}

- (void)connectToServer {
    _serverConnectionStatusLabel.text = @"Server Status: Connecting...";
    NSLog(@"Setting up connection to %@ : %i", ipAddress, [port intValue]);
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef) ipAddress, [port intValue], &readStream, &writeStream);

    messages = [[NSMutableArray alloc] init];

    [self open];
}

- (void)disconnect {
    _serverConnectionStatusLabel.text = @"Server Status: Disconnecting...";
    [self close];
}

- (void)open {

    NSLog(@"Opening streams.");

    outputStream = (__bridge NSOutputStream *)writeStream;
    inputStream = (__bridge NSInputStream *)readStream;

    [outputStream setDelegate:self];
    [inputStream setDelegate:self];

    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [outputStream open];
    [inputStream open];
}

- (void)close {
    NSLog(@"Closing streams.");
    [inputStream close];
    [outputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    inputStream = nil;
    outputStream = nil;
}

#pragma mark DJI Methods

- (void) configureConnectionToProduct
{
    _uavConnectionStatusLabel.text = @"UAV Status: Connecting...";
#if ENABLE_DEBUG_MODE
        [DJISDKManager enableBridgeModeWithBridgeAppIP:@"192.168.0.26"];
#else
        [DJISDKManager startConnectionToProduct];
#endif
        [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
        [[DJIVideoPreviewer instance] start];
}

#pragma mark DJISDKManagerDelegate Method

- (void)productConnected:(DJIBaseProduct *)product
{
    if (product){
        _uavConnectionStatusLabel.text = @"UAV Status: Connected";
        
        DJIFlightController* flightController = [DJIUtils fetchFlightController];
        if (flightController) {
            flightController.delegate = self;
        }
        
        DJICamera *camera = [DJIUtils fetchCamera];
        if (camera != nil) {
            camera.delegate = self;
        }
        
        DJIBattery *battery = [DJIUtils fetchBattery];
        if (battery != nil) {
            battery.delegate = self;
        }
        
        [flightController getSerialNumberWithCompletion:^(NSString * serialNumber, NSError * error) {
            self->_drone_serial = serialNumber;
        }];
        
    }
    
    //[self setCoreTelemetryKeyedParameters];
}

- (void)productDisconnected
{
    _uavConnectionStatusLabel.text = @"UAV Status: Not Connected";
}

#pragma mark - DJIVideoFeedListener

-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
}

#pragma mark - DJICameraDelegate

-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
{
}

- (void)camera:(DJICamera *_Nonnull)camera
    didReceiveVideoData:(nonnull uint8_t *)videoBuffer
                 length:(size_t)size
{
    
}

#pragma mark - DJIBatteryDelegate
- (void)battery:(DJIBattery *)battery didUpdateState:(DJIBatteryState *)state
{
    NSLog(@"reeewtf");
    self->_bat_level = state.chargeRemainingInPercent;
}

#pragma mark - DJIBatteryAggregationDelegate
- (void) batteriesDidUpdateState:(DJIBatteryAggregationState *)state {
    NSLog(@"reee");
    self->_bat_level = state.chargeRemainingInPercent;
}

#pragma mark - DJIFlightControllerDelegate

- (void)flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state
{
    self->_GNSSSignal = (UInt8)(state.GPSSignalLevel);
    if([DJIUtils gpsStatusIsGood:[state GPSSignalLevel]])
    {
        self->_latitude = state.aircraftLocation.coordinate.latitude;
        self->_longitude = state.aircraftLocation.coordinate.longitude;
        self->_HAG = state.aircraftLocation.altitude;
        self->_altitude = state.takeoffLocationAltitude + self->_HAG;
        
    }
    
    self->_isFlying = state.isFlying ? 1 : 0;
    self->_velocity_n = state.velocityX;
    self->_velocity_e = state.velocityY;
    self->_velocity_d = state.velocityZ;
    self->_yaw = state.attitude.yaw;
    self->_pitch = state.attitude.pitch;
    self->_roll = state.attitude.roll;
    
    self->_GNSSSatCount = state.satelliteCount;
    self->_max_height = state.hasReachedMaxFlightHeight ? 1 : 0;
    self->_max_dist = state.hasReachedMaxFlightRadius ? 1 : 0;
    if (state.isLowerThanSeriousBatteryWarningThreshold) {
        self->_bat_warning = 2;
    } else {
        if (state.isLowerThanBatteryWarningThreshold) {
            self->_bat_warning = 1;
        } else {
            self->_bat_warning = 0;
        }
    }
    self->_wind_level = state.windWarning;
    self->_flight_mode = state.flightMode;
}

@end
