//
//  ViewController.m
//  DroneClient
//
//  Created by Ben Choi on 2/17/21.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _testLabel.text = @"wow";
}

- (IBAction)onButtonClick:(id)sender {
    _testLabel.text = @"okok";
}

@end
