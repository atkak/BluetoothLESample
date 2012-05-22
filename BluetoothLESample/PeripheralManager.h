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
- (void)didConnectPeripheral;
- (void)didDisconnectPeripheral;
- (void)notifyAlertReady;
- (void)checkBatteryReady;
- (void)didCheckBattery:(int)value;

@end

@interface PeripheralManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) id<PeripheralManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *deviceName;

- (void)scanForPeripherals;
- (void)notifyAlert;
- (void)checkBattery;

@end
