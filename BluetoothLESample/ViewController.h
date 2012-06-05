//
//  ViewController.h
//  BluetoothLESample
//
//  Created by 敦史 掛川 on 12/05/21.
//  Copyright (c) 2012年 Classmethod Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PeripheralManager.h"

@interface ViewController : UIViewController <PeripheralManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *alertButton;
@property (weak, nonatomic) IBOutlet UIButton *batteryButton;
- (IBAction)connectButtonTouched:(id)sender;
- (IBAction)alertButtonTouched:(id)sender;
- (IBAction)batteryButtonTouched:(id)sender;

@end
