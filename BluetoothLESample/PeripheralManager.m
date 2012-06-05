//
//  PeripheralManager.m
//  BluetoothLETest
//
//  Created by 敦史 掛川 on 12/05/21.
//  Copyright (c) 2012年 Classmethod Inc. All rights reserved.
//

#import "PeripheralManager.h"

// サービスUUID:Immediate Alert
NSString *kUUIDServiceImmediateAlert = @"1802";
// サービスUUID:Battery Service
NSString *kUUIDServiceBatteryService = @"180F";
// キャラクタリスティックUUID:Alert Level
NSString *kUUIDCharacteristicsAlertLevel = @"2A06";
// キャラクタリスティックUUID:Battery Level
NSString *kUUIDCharacteristicsBatteryLevel = @"2A19";

@interface PeripheralManager () {
    CBCentralManager *centralManager;
    CBPeripheral *targetPeripheral;
    CBCharacteristic *alertLevelCharacteristic;
    CBCharacteristic *batteryLevelCharacteristic;
}

@end

@implementation PeripheralManager

@synthesize delegate = _delegate;

#pragma mark - Properties

- (NSString *)deviceName
{
    if (!targetPeripheral)
    {
        return nil;
    }
    return targetPeripheral.name;
}

#pragma mark - View lifecycle methods

- (id)init
{
    self = [super init];
    if (self)
    {
        // Bluetoothの接続マネージャーを生成
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

#pragma mark - Public methods

- (void)scanForPeripheralsAndConnect
{
    // 探索対象のデバイスが持つサービスを指定
    NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDServiceImmediateAlert], 
                         [CBUUID UUIDWithString:kUUIDServiceBatteryService], nil];
    // 単一デバイスの発見イベントを重複して発行させない
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] 
                                                        forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    // デバイスの探索を開始
    [centralManager scanForPeripheralsWithServices:services options:options];
}

- (void)notifyAlert
{
    // HighAlertを指定
    ushort value = 2;
    NSMutableData *data = [NSMutableData dataWithBytes:&value length:8];
    // alertLevelの値を書き込んで、接続デバイスに通知
    [targetPeripheral writeValue:data 
              forCharacteristic:alertLevelCharacteristic 
                           type:CBCharacteristicWriteWithoutResponse];
}

- (void)checkBattery
{
    // 接続デバイスのバッテリー情報取得
    [targetPeripheral readValueForCharacteristic:batteryLevelCharacteristic];
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManager:(CBCentralManager *)central 
 didDiscoverPeripheral:(CBPeripheral *)peripheral 
     advertisementData:(NSDictionary *)advertisementData 
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"didDiscoverPeripheral UUID:%@ advertisementData:%@", peripheral.UUID, [advertisementData description]);
    
    targetPeripheral = peripheral;
    peripheral.delegate = self;
    
    // 発見されたデバイスに接続
    if (!peripheral.isConnected)
    {
        [centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral");
    
    // 外部デバイスとの接続完了を通知
    [self.delegate peripheralManagerDidConnectPeripheral:self];
    
    // 探索するサービスを指定
    NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDServiceImmediateAlert], 
                         [CBUUID UUIDWithString:kUUIDServiceBatteryService], nil];
    // サービスの探索を開始
    [peripheral discoverServices:services];
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"didFailToConnectPeripheral %@", [error localizedDescription]);
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral %@", [error localizedDescription]);
    
    [self.delegate peripheralManagerDidDisconnectPeripheral:self];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"centralManagerDidUpdateState poweredOn");
            break;
            
        case CBCentralManagerStatePoweredOff:
            NSLog(@"centralManagerDidUpdateState poweredOff");
            break;
            
        case CBCentralManagerStateResetting:
            NSLog(@"centralManagerDidUpdateState resetting");
            break;
            
        case CBCentralManagerStateUnauthorized:
            NSLog(@"centralManagerDidUpdateState unauthorized");
            break;
            
        case CBCentralManagerStateUnsupported:
            NSLog(@"centralManagerDidUpdateState unsupported");
            break;
            
        case CBCentralManagerStateUnknown:
            NSLog(@"centralManagerDidUpdateState unknown");
            break;
            
        default:
            break;
    }
}

#pragma mark - CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverServices error: %@", error.localizedDescription);
        return;
    }
    
    if (peripheral.services.count == 0)
    {
        NSLog(@"didDiscoverServices no services");
        return;
    }
    
    NSLog(@"didDiscoverServices services:%@", [peripheral.services description]);
    
    for (CBService *service in peripheral.services)
    {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kUUIDServiceImmediateAlert]])
        {
            // Immediate Alertサービスを発見した場合、Alert Levelキャラクタリスティックの探索を開始
            [peripheral discoverCharacteristics:[NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDCharacteristicsAlertLevel], nil] forService:service];
        }
        else if ([service.UUID isEqual:[CBUUID UUIDWithString:kUUIDServiceBatteryService]])
        {
            // Battery Serviceサービスを発見した場合、Battery Levelキャラクタリスティックの探索を開始
            [peripheral discoverCharacteristics:[NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDCharacteristicsBatteryLevel], nil] forService:service];
        } 
    }
}

- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverCharacteristicsForService:(CBService *)service 
             error:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverCharacteristics error: %@", error.localizedDescription);
        return;
    }
    
    if (service.characteristics.count == 0)
    {
        NSLog(@"didDiscoverCharacteristics no characteristics");
        return;
    }
    
    NSLog(@"didDiscoverCharacteristics %@", [service.characteristics description]);

    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kUUIDCharacteristicsAlertLevel]])
        {
            // Alert Levelキャラクタリスティックオブジェクトへの参照を保管
            alertLevelCharacteristic = characteristic;
            // 外部デバイス鳴動指示準備完了を通知
            [self.delegate peripheralManagerNotifyAlertReady:self];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kUUIDCharacteristicsBatteryLevel]])
        {
            // Battery Levelキャラクタリスティックオブジェクトへの参照を保管
            batteryLevelCharacteristic = characteristic;
            // 外部デバイスバッテリー情報取得準備完了を通知
            [self.delegate peripheralManagerCheckBatteryReady:self];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error
{
    if (error)
    {
        NSLog(@"didUpdateValueForCharacteristic error: %@", error.localizedDescription);
        return;
    }
    
    NSLog(@"didUpdateValueForCharacteristic");
    
    if ([characteristic isEqual:batteryLevelCharacteristic])
    {
        // バッテリー情報の値を取得
        ushort value;
        NSMutableData *data = [NSMutableData dataWithData:characteristic.value];
        [data increaseLengthBy:8];
        [data getBytes:&value length:sizeof(value)];
        // バッテリー情報取得完了を通知
        [self.delegate peripheralManager:self didCheckBattery:value];
    }
}

@end
