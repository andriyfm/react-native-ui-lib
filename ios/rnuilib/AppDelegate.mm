#import "AppDelegate.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#import <React/RCTCxxBridgeDelegate.h>
#import <ReactCommon/RCTTurboModuleManager.h>
#import <ReactNativeNavigation/ReactNativeNavigation.h>


// Reanimated related headers (start)
#import <React/RCTDataRequestHandler.h>
#import <React/RCTFileRequestHandler.h>
#import <React/RCTHTTPRequestHandler.h>
#import <React/RCTNetworking.h>
#import <React/RCTLocalAssetImageLoader.h>
#import <React/RCTGIFImageDecoder.h>
#import <React/RCTImageLoader.h>
#import <React/JSCExecutorFactory.h>
#import <RNReanimated/RETurboModuleProvider.h>
#import <RNReanimated/REAModule.h>
// Reanimated related headers (end)

#if DEBUG
#import <FlipperKit/FlipperClient.h>
#import <FlipperKitLayoutPlugin/FlipperKitLayoutPlugin.h>
#import <FlipperKitUserDefaultsPlugin/FKUserDefaultsPlugin.h>
#import <FlipperKitNetworkPlugin/FlipperKitNetworkPlugin.h>
#import <SKIOSNetworkPlugin/SKIOSNetworkAdapter.h>
#import <FlipperKitReactPlugin/FlipperKitReactPlugin.h>

static void InitializeFlipper(UIApplication *application) {
  FlipperClient *client = [FlipperClient sharedClient];
  SKDescriptorMapper *layoutDescriptorMapper = [[SKDescriptorMapper alloc] initWithDefaults];
  [client addPlugin:[[FlipperKitLayoutPlugin alloc] initWithRootNode:application withDescriptorMapper:layoutDescriptorMapper]];
  [client addPlugin:[[FKUserDefaultsPlugin alloc] initWithSuiteName:nil]];
  [client addPlugin:[FlipperKitReactPlugin new]];
  [client addPlugin:[[FlipperKitNetworkPlugin alloc] initWithNetworkAdapter:[SKIOSNetworkAdapter new]]];
  [client start];
}
#endif

/* Reanimated */
@interface AppDelegate() <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
    RCTTurboModuleManager *_turboModuleManager;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
  InitializeFlipper(application);
#endif
  
  RCTEnableTurboModule(YES);

//  NSURL *jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"demo" fallbackResource:nil];
//  [ReactNativeNavigation bootstrap:jsCodeLocation launchOptions:launchOptions];
  [ReactNativeNavigation bootstrapWithDelegate:self launchOptions:launchOptions];
  
  return YES;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"demo" fallbackResource:nil];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

- (NSArray<id<RCTBridgeModule>> *)extraModulesForBridge:(RCTBridge *)bridge {
  return [ReactNativeNavigation extraModulesForBridge:bridge];
}


- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge
{
  _bridge_reanimated = bridge;
  _turboModuleManager = [[RCTTurboModuleManager alloc] initWithBridge:bridge delegate:self];

 #if RCT_DEV
  [_turboModuleManager moduleForName:"RCTDevMenu"]; // <- add
 #endif
 __weak __typeof(self) weakSelf = self;
 return std::make_unique<facebook::react::JSCExecutorFactory>([weakSelf, bridge](facebook::jsi::Runtime &runtime) {
   if (!bridge) {
     return;
   }
   __typeof(self) strongSelf = weakSelf;
   if (strongSelf) {
     [strongSelf->_turboModuleManager installJSBindingWithRuntime:&runtime];
   }
 });
}

- (Class)getModuleClassFromName:(const char *)name
{
 return facebook::react::RETurboModuleClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                     jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
 return facebook::react::RETurboModuleProvider(name, jsInvoker);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      instance:(id<RCTTurboModule>)instance
                                                     jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
 return facebook::react::RETurboModuleProvider(name, instance, jsInvoker);
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
 if (moduleClass == RCTImageLoader.class) {
   return [[moduleClass alloc] initWithRedirectDelegate:nil loadersProvider:^NSArray<id<RCTImageURLLoader>> *{
     return @[[RCTLocalAssetImageLoader new]];
   } decodersProvider:^NSArray<id<RCTImageDataDecoder>> *{
     return @[[RCTGIFImageDecoder new]];
   }];
 } else if (moduleClass == RCTNetworking.class) {
   return [[moduleClass alloc] initWithHandlersProvider:^NSArray<id<RCTURLRequestHandler>> *{
     return @[
       [RCTHTTPRequestHandler new],
       [RCTDataRequestHandler new],
       [RCTFileRequestHandler new],
     ];
   }];
 }
 return [moduleClass new];
}


@end
