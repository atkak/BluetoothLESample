//
//  PeripheralManager.m
//  BluetoothLETest
//
//  Created by 敦史 掛川 on 12/05/21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PeripheralManager.h"

NSString *kUUIDImmediateAlert = @"1802";
NSString *kUUIDBatteryService = @"180F";
NSString *kUUIDCharacteristicsAlertLevel = @"2A06";
NSString *kUUIDCharacteristicsBatteryLevel = @"2A19";

@interface PeripheralManager () {
    CBCentralManager *centralManager;
    CBPeripheral *targetPerpheral;
    CBCharacteristic *alertLevelCharacteristic;
    CBCharacteristic *batteryLevelCharacteristic;
}

@end

@implementation PeripheralManager

@synthesize delegate = _delegate;
@synthesize deviceName = _deviceName;

- (id)init
{
    self = [super init];
    if (self) {
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)scanForPeripherals
{
    NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDImmediateAlert], 
                         [CBUUID UUIDWithString:kUUIDBatteryService], nil];
    [centralManager scanForPeripheralsWithServices:services options:nil];
}

- (void)notifyAlert
{
    int value = 2;
    NSMutableData *data = [NSMutableData dataWithBytes:&value length:8];
    [targetPerpheral writeValue:data 
              forCharacteristic:alertLevelCharacteristic 
                           type:CBCharacteristicWriteWithoutResponse];
}

- (void)checkBattery
{
    [targetPerpheral readValueForCharacteristic:batteryLevelCharacteristic];
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManager:(CBCentralManager *)central 
 didDiscoverPeripheral:(CBPeripheral *)peripheral 
     advertisementData:(NSDictionary *)advertisementData 
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"didDiscoverPeripheral UUID:%@ advertisementData:%@", peripheral.UUID, [advertisementData description]);
    
    targetPerpheral = peripheral;
    peripheral.delegate = self;
    
    if ([advertisementData.allKeys containsObject:@"kCBAdvDataLocalName"]) {
        _deviceName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    }
    
    if (!peripheral.isConnected) {
        [centralManager connectPeripheral:peripheral options:nil];
    }
}

//- (void)centralManager:(CBCentralManager *)central 
//didRetrievePeripherals:(NSArray *)peripherals
//{
//    NSLog(@"didRetrievePeripheral");
//    
//    [centralManager connectPeripheral:peripherals options:nil];
//}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral");
    
    [self.delegate didConnectPeripheral];
    
    NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDImmediateAlert], 
                         [CBUUID UUIDWithString:kUUIDBatteryService], nil];
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
    
    [self.delegate didDisconnectPeripheral];
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
    if (error) {
        NSLog(@"didDiscoverServices error: %@", error.localizedDescription);
        return;
    }
    
    if (peripheral.services.count == 0) {
        NSLog(@"didDiscoverServices no services");
        return;
    }
    
    NSLog(@"didDiscoverServices services:%@", [peripheral.services description]);
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kUUIDImmediateAlert]]) {
            [peripheral discoverCharacteristics:[NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDCharacteristicsAlertLevel], nil] forService:service];
        } else if ([service.UUID isEqual:[CBUUID UUIDWithString:kUUIDBatteryService]]) {
            [peripheral discoverCharacteristics:[NSArray arrayWithObjects:[CBUUID UUIDWithString:kUUIDCharacteristicsBatteryLevel], nil] forService:service];
        } 
    }
}

- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverCharacteristicsForService:(CBService *)service 
             error:(NSError *)error
{
    if (error) {
        NSLog(@"didDiscoverCharacteristics error: %@", error.localizedDescription);
        return;
    }
    
    if (service.characteristics.count == 0) {
        NSLog(@"didDiscoverCharacteristics no characteristics");
        return;
    }
    
    NSLog(@"didDiscoverCharacteristics %@", [service.characteristics description]);

    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kUUIDCharacteristicsAlertLevel]]) {
            alertLevelCharacteristic = characteristic;
            [self.delegate notifyAlertReady];
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kUUIDCharacteristicsBatteryLevel]]) {
            batteryLevelCharacteristic = characteristic;
            [self.delegate checkBatteryReady];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error
{
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic error: %@", error.localizedDescription);
        return;
    }
    
    NSLog(@"didUpdateValueForCharacteristic");
    
    if ([characteristic isEqual:batteryLevelCharacteristic]) {
        int intValue;
        NSMutableData *data = [NSMutableData dataWithData:characteristic.value];
        [data increaseLengthBy:24];
        [data getBytes:&intValue length:sizeof(intValue)];
        
        [self.delegate didCheckBattery:intValue];
    }
}

@end
