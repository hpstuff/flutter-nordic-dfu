#import <Flutter/Flutter.h>
@import iOSDFULibrary;

@interface FlutterNordicDfuPlugin : NSObject<FlutterPlugin, NSNetServiceDelegate, DFUProgressDelegate>
@property (nonatomic, copy) FlutterMethodChannel* channel;
@property (nonatomic, retain) NSString* deviceAddress;
- (void)startDfu:(NSString* )address name:(NSString* )name filePath:(NSString* )filePath result:(FlutterResult)result;
@end
