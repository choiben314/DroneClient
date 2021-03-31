//
//  ConfigViewController.m
//  DroneClient
//
//  Created by Ben Choi on 2/17/21.
//

#import "ConfigViewController.h"
#import "ConnectionController.h"
#import <DJISDK/DJISDK.h>
#import "Constants.h"

@interface ConfigViewController ()<DJISDKManagerDelegate>

@end

@implementation ConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerApp];
    
    UITapGestureRecognizer *tapGestureRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    [tapGestureRecognizer setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tapGestureRecognizer];
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
        _registrationStatusLabel.text = @"Registration Status: SUCCESS";
    }
    NSLog(@"%@", message);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"connect"]){
        ConnectionController *controller = (ConnectionController *)segue.destinationViewController;
        controller->ipAddress = _ipAddressTextField.text;
        controller->port = _portTextField.text;
    }
}

@end
