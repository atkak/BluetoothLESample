//
//  PeripheralManager.h
//  BluetoothLETest
//
//  Created by 敦史 掛川 on 12/05/21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol PeripheralManagerDelegate <NSObject>

@optional
// 外部デバイスへの接続完了時に呼ばれる
- (void)didConnectPeripheral;
// 外部デバイスとの接続の切断時に呼ばれる
- (void)didDisconnectPeripheral;
// 外部デバイスの鳴動指示が利用可能になった時に呼ばれる
- (void)notifyAlertReady;
// 外部デバイスのバッテリー情報取得が利用可能になった時に呼ばれる
- (void)checkBatteryReady;
// 外部でバイスのバッテリー情報取得完了時に呼ばれる
- (void)didCheckBattery:(ushort)value;

@end

@interface PeripheralManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) id<PeripheralManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *deviceName;

- (void)scanForPeripheralsAndConnect;
- (void)notifyAlert;
- (void)checkBattery;

@end
