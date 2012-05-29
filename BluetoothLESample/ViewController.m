//
//  ViewController.m
//  BluetoothLESample
//
//  Created by 敦史 掛川 on 12/05/21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    PeripheralManager *manager;
}

@end

@implementation ViewController

@synthesize label;
@synthesize connectButton;
@synthesize alertButton;
@synthesize batteryButton;

#pragma mark - View lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.label.text = @"未接続";
    self.alertButton.enabled = NO;
    self.batteryButton.enabled = NO;
}

- (void)viewDidUnload
{
    [self setLabel:nil];
    [self setConnectButton:nil];
    [self setAlertButton:nil];
    [self setBatteryButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - PefipheralManagerDelegate methods

- (void)didConnectPeripheral
{
    self.label.text = [NSString stringWithFormat:@"接続中:%@", manager.deviceName];
}

- (void)didDisconnectPeripheral
{
    self.label.text = @"未接続";
    self.connectButton.enabled = YES;
    self.alertButton.enabled = NO;
    self.batteryButton.enabled = NO;
}

- (void)notifyAlertReady
{
    self.alertButton.enabled = YES;
}

- (void)checkBatteryReady
{
    self.batteryButton.enabled = YES;
}

- (void)didCheckBattery:(ushort)value
{
    // 接続デバイスのバッテリー残量をアラートで表示
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"バッテリー残量" 
                                                    message:[NSString stringWithFormat:@"接続先デバイスのバッテリー残量は%d%%です", value] 
                                                   delegate:nil 
                                          cancelButtonTitle:nil 
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

#pragma mark - Handlers

// 接続ボタンタップイベントハンドラ
- (IBAction)connectButtonTouched:(id)sender
{
    self.connectButton.enabled = NO;
    self.label.text = @"検索中";
    // Bluetoothデバイスのマネージャーを作成
    manager = [[PeripheralManager alloc] init];
    manager.delegate = self;
    // デバイスのスキャンと接続を開始
    [manager scanForPeripheralsAndConnect];
}

// アラートボタンタップイベントハンドラ
- (IBAction)alertButtonTouched:(id)sender
{
    // 接続デバイスを鳴動させる
    [manager notifyAlert];
}

// バッテリーチェックボタンタップイベントハンドラ
- (IBAction)batteryButtonTouched:(id)sender
{
    // 接続デバイスのバッテリー情報を取得
    [manager checkBattery];
}
@end
