#import "FlutterNordicDfuPlugin.h"

@implementation FlutterNordicDfuPlugin {
  NSObject<FlutterPluginRegistrar>* registrar;
}

FlutterResult pendingResult;

- (instancetype)initWithChannel:(FlutterMethodChannel* )channel {
  self = [super init];
  if (self) {
    _channel = channel;
  }
  return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.timeyaa.flutter_nordic_dfu/method"
            binaryMessenger:[registrar messenger]];
  FlutterNordicDfuPlugin* instance = [[FlutterNordicDfuPlugin alloc] initWithChannel:channel];
  instance->registrar = registrar;
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"startDfu" isEqualToString:call.method]) {
    NSString *name = call.arguments[@"name"];
    NSString *address = call.arguments[@"address"];
    NSString *filePath = call.arguments[@"filePath"];
    
    if (address == NULL || filePath == NULL) {
      result(@{@"code": @"ABNORMAL_PARAMETER", @"message": @"address and filePath are required"});
      return;
    }
    
    NSString* key = [registrar lookupKeyForAsset:filePath];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:key ofType:NULL];
    
    [self startDfu:address name:name filePath:path result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)startDfu:(NSString* )address name:(NSString* )name filePath:(NSString* )filePath result:(FlutterResult)result {
  
  NSUUID* uuid = [[NSUUID alloc] initWithUUIDString:address];
  if (uuid == NULL) {
    result(@{@"code": @"DEVICE_ADDRESS_ERROR", @"message": @"Device address conver to uuid failed", @"details": @"Device uuid \(address) convert to uuid failed"});
    return;
  }
  
  DFUFirmware* firmware = [[DFUFirmware alloc] initWithUrlToZipFile: [[NSURL alloc] initFileURLWithPath:filePath]];
  
  if (firmware == NULL) {
    result(@{@"code": @"DFU_FIRMWARE_NOT_FOUND", @"message": @"Could not dfu zip file"});
    return;
  }
  
  DFUServiceInitiator* dfuInitiator = [[[DFUServiceInitiator alloc] initWithQueue:dispatch_get_main_queue() delegateQueue:dispatch_get_main_queue() progressQueue:dispatch_get_main_queue() loggerQueue:dispatch_get_main_queue()] withFirmware:firmware];

  
  dfuInitiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = YES;
  pendingResult = result;
  _deviceAddress = address;
  dfuInitiator.delegate = self;
  dfuInitiator.progressDelegate = self;
  [dfuInitiator startWithTargetWithIdentifier:uuid];
}

- (void)dfuStateDidChangeTo:(enum DFUState)state {
  switch (state) {
    case DFUStateCompleted:
      pendingResult(_deviceAddress);
      pendingResult = NULL;
      [_channel invokeMethod:@"onDfuCompleted" arguments: _deviceAddress];
      break;
    case DFUStateDisconnecting:
      [_channel invokeMethod:@"onDeviceDisconnecting" arguments: _deviceAddress];
      break;
    case DFUStateAborted:
      pendingResult(@{
                       @"code": @"DFU_ABORRED",
                       @"message": [NSString stringWithFormat:@"Device address: %@", _deviceAddress]
                      });
      pendingResult = NULL;
      [_channel invokeMethod:@"onDfuAborted" arguments: _deviceAddress];
      break;
    case DFUStateConnecting:
      [_channel invokeMethod:@"onDeviceConnecting" arguments: _deviceAddress];
      break;
    case DFUStateStarting:
      [_channel invokeMethod:@"onDfuProcessStarting" arguments: _deviceAddress];
      break;
    case DFUStateEnablingDfuMode:
      [_channel invokeMethod:@"onEnablingDfuMode" arguments: _deviceAddress];
      break;
    case DFUStateValidating:
      [_channel invokeMethod:@"onFirmwareValidating" arguments: _deviceAddress];
      break;
    case DFUStateUploading:
      [_channel invokeMethod:@"onFirmwareUploading" arguments: _deviceAddress];
      break;
    default:
      break;
  }
}

- (void)dfuError:(enum DFUError)error didOccurWithMessage:(NSString * _Nonnull)message {
  [_channel invokeMethod:@"onError" arguments: _deviceAddress];
  pendingResult(@{
                   @"code": @"DFU_FAILED",
                   @"message": [NSString stringWithFormat:@"Device address: %@", _deviceAddress]
                   });
  pendingResult = NULL;
}


- (void)dfuProgressDidChangeFor:(NSInteger)part outOf:(NSInteger)totalParts to:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond {
  [_channel invokeMethod:@"onProgressChanged"
               arguments: @{
                            @"percent": [NSNumber numberWithLong: progress],
                            @"speed": [NSNumber numberWithDouble: currentSpeedBytesPerSecond],
                            @"avgSpeed": [NSNumber numberWithDouble: avgSpeedBytesPerSecond],
                            @"currentPart": [NSNumber numberWithLong: part],
                            @"partsTotal": [NSNumber numberWithLong: totalParts],
                            @"deviceAddress": _deviceAddress
                            }];
}

@end
