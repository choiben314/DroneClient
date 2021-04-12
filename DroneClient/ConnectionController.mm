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
#import "VideoPreviewerSDKAdapter.h"
#import "ImageUtils.h"
#import "Image.hpp"

@interface ConnectionController ()<DJISDKManagerDelegate, DJICameraDelegate, DJIBatteryDelegate, DJIBatteryAggregationDelegate, DJIFlightControllerDelegate, NSStreamDelegate, DJIVideoFeedListener, VideoFrameProcessor>

@end

@implementation ConnectionController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerApp];
    [self configureConnectionToProduct];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[DJIVideoPreviewer instance] unSetView];
           
    if (self.previewerAdapter) {
        [self.previewerAdapter stop];
        self.previewerAdapter = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self connectToServer];
}

#pragma mark TCP Connection

- (void) sendPacket:(DroneInterface::Packet *)packet {
    NSData *data = [[NSData alloc] initWithBytesNoCopy:packet->m_data.data() length:packet->m_data.size() freeWhenDone:false];
    const unsigned char *bytes= (const unsigned char *)(data.bytes);
    [outputStream write:bytes maxLength:[data length]];
}

- (void) sendPacket_CoreTelemetry {
    DroneInterface::Packet_CoreTelemetry packet_core;
    DroneInterface::Packet packet;
    
    packet_core.IsFlying = self->_isFlying;
    packet_core.Latitude = self->_latitude;
    packet_core.Longitude = self->_longitude;
    packet_core.Altitude = self->_altitude;
    packet_core.HAG = self->_HAG;
    packet_core.V_N = self->_velocity_n;
    packet_core.V_N = self->_velocity_e;
    packet_core.V_D = self->_velocity_d;
    packet_core.Yaw = self->_yaw;
    packet_core.Pitch = self->_pitch;
    packet_core.Roll = self->_roll;
    
    packet_core.Serialize(packet);
    
    [self sendPacket:&packet];
}

- (void) sendPacket_ExtendedTelemetry {
    DroneInterface::Packet_ExtendedTelemetry packet_extended;
    DroneInterface::Packet packet;
    
    packet_extended.GNSSSatCount = self->_GNSSSatCount;
    packet_extended.GNSSSignal = self->_GNSSSignal;
    packet_extended.MaxHeight =self->_max_height;
    packet_extended.MaxDist = self->_max_dist;
    packet_extended.BatLevel = self->_bat_level;
    packet_extended.BatWarning = self->_bat_warning;
    packet_extended.WindLevel = self->_wind_level;
    packet_extended.DJICam = self->_dji_cam;
    packet_extended.FlightMode = self->_flight_mode;
    packet_extended.MissionID = self->_mission_id;
    packet_extended.DroneSerial = std::string([self->_drone_serial UTF8String]);
    
    packet_extended.Serialize(packet);
    
    [self sendPacket:&packet];
}

- (void) sendPacket_Image {
    DroneInterface::Packet_Image packet_image;
    DroneInterface::Packet packet;
    
    [self showCurrentFrameImage];
    
    CVPixelBufferRef pixelBuffer;
    if (self->_currentPixelBuffer) {
        pixelBuffer = self->_currentPixelBuffer;
        UIImage* image = [self imageFromPixelBuffer:pixelBuffer];
        packet_image.TargetFPS = [DJIVideoPreviewer instance].currentStreamInfo.frameRate;
        unsigned char *bitmap = [ImageUtils convertUIImageToBitmapRGBA8:image];
        packet_image.Frame = new Image(bitmap, image.size.height, image.size.width, 4);
    }
    
    packet_image.Serialize(packet);
    
    [self sendPacket:&packet];
}

- (void) sendPacket_MessageString:(NSString*)msg ofType:(UInt8)type {
    
    DroneInterface::Packet_MessageString packet_msg;
    DroneInterface::Packet packet;
    
    packet_msg.Type = type;
    packet_msg.Message = std::string([msg UTF8String]);
    
    packet_msg.Serialize(packet);
    
    [self sendPacket: &packet];
}

- (IBAction)sendDebugMessage:(id)sender {
//    [self sendPacket_MessageString: @"Testing the message string..." ofType: 2];
    [self sendPacket_ExtendedTelemetry];
//    [self showCurrentFrameImage];
//    [self sendPacket_Image];
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

- (void) configureConnectionToProduct {
    _uavConnectionStatusLabel.text = @"UAV Status: Connecting...";
#if ENABLE_DEBUG_MODE
    [DJISDKManager enableBridgeModeWithBridgeAppIP:@"192.168.43.110"];
#else
    [DJISDKManager startConnectionToProduct];
#endif
    [DJISDKManager startConnectionToProduct];

    [[DJIVideoPreviewer instance] start];
    self.previewerAdapter = [VideoPreviewerSDKAdapter adapterWithDefaultSettings];
    [self.previewerAdapter start];
    [[DJIVideoPreviewer instance] registFrameProcessor:self];
    [[DJIVideoPreviewer instance] setEnableHardwareDecode:true];
}

- (void) videoProcessFrame:(VideoFrameYUV *)frame {
    if ((frame->cv_pixelbuffer_fastupload != nil)) {
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef) frame->cv_pixelbuffer_fastupload;
        if (self->_currentPixelBuffer) {
            CVPixelBufferRelease(self->_currentPixelBuffer);
        }
        self->_currentPixelBuffer = pixelBuffer;
        CVPixelBufferRetain(pixelBuffer);
    } else {
        self->_currentPixelBuffer = nil;
    }
}

- (BOOL)videoProcessorEnabled {
    return YES;
}

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer =  pixelBufferRef;
    CIImage* sourceImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer options:nil];
    CGSize size = sourceImage.extent.size;
    UIGraphicsBeginImageContext(size);
    CGRect rect;
    rect.origin = CGPointZero;
    rect.size = size;
    UIImage *remImage = [UIImage imageWithCIImage:sourceImage];
    [remImage drawInRect:rect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (void)showCurrentFrameImage {
    CVPixelBufferRef pixelBuffer;
    if (self->_currentPixelBuffer) {
        pixelBuffer = self->_currentPixelBuffer;
        UIImage* image = [self imageFromPixelBuffer:pixelBuffer];
        if (image) {
            UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
            imgView.image = image;
            [self.fpvPreviewView addSubview:imgView];
            _aircraftLocationState.text = [NSString stringWithFormat:@"Height: %.2f, Width: %.2f", image.size.height, image.size.width];
        }
    }
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
    
    [self setExtendedTelemetryKeyedParameters];
}

- (void)productDisconnected
{
    _uavConnectionStatusLabel.text = @"UAV Status: Not Connected";
}

- (void)registerApp
{
   [DJISDKManager registerAppWithDelegate:self];
}

- (void)appRegisteredWithError:(NSError *)error
{
    NSString* message;
    if (error) {
        message = @"Register App Failed! Please enter your App Key in the plist file and check the network.";
        _registrationStatusLabel.text = @"Registration Status: FAILED";
        
    } else {
        message = @"App successfully registered";
        _registrationStatusLabel.text = @"Registration Status: Registered";
    }
    NSLog(@"%@", message);
}

#pragma mark - DJICameraDelegate

-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
{
    if (systemState.mode == DJICameraModePlayback ||
        systemState.mode == DJICameraModeMediaDownload) {
        if (self->needToSetMode) {
            self->needToSetMode = NO;
            [camera setMode:DJICameraModeShootPhoto withCompletion:^(NSError * _Nullable error) {
            }];
        }
    }
}

- (void)camera:(DJICamera *_Nonnull)camera
    didReceiveVideoData:(nonnull uint8_t *)videoBuffer
                 length:(size_t)size
{
    
}

#pragma mark - DJIBatteryDelegate

// Use keyed parameters method for battery level because DJIBatteryDelegate unresponsive for some reason.
- (void)setExtendedTelemetryKeyedParameters {
    DJIKey * batteryOneKey = [DJIBatteryKey keyWithIndex:0 andParam:DJIBatteryParamChargeRemainingInPercent];
    DJIKey * batteryTwoKey = [DJIBatteryKey keyWithIndex:1 andParam:DJIBatteryParamChargeRemainingInPercent];
    [[DJISDKManager keyManager] startListeningForChangesOnKey: batteryOneKey
                                                 withListener: self
                                               andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
                                                if (newKeyedValue) {
                                                    self->_bat_level_one = [newKeyedValue.value intValue];
                                                    self->_bat_level = (self->_bat_level_one + self->_bat_level_two) / 2;
                                                }
                                            }];
    [[DJISDKManager keyManager] startListeningForChangesOnKey: batteryTwoKey
                                                 withListener: self
                                               andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
                                                if (newKeyedValue) {
                                                    self->_bat_level_two = [newKeyedValue.value intValue];
                                                    self->_bat_level = (self->_bat_level_one + self->_bat_level_two) / 2;
                                                }
                                            }];
}

#pragma mark - DJIFlightControllerDelegate

- (void)flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state
{
    self->_GNSSSignal = [DJIUtils getGNSSSignal:[state GPSSignalLevel]];
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
    self->_wind_level = [DJIUtils getWindLevel:[state windWarning]];
    self->_flight_mode = [DJIUtils getFlightMode:[state flightMode]];

    if (!self->_camera.isConnected) {
        self->_dji_cam = 0;
    }
    self->_mission_id = 0;
}

@end
