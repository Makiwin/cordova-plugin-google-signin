#import <Cordova/CDVPlugin.h>
#import <GoogleSignIn/GoogleSignIn.h>

@interface GoogleSignIn : CDVPlugin

@property (nonatomic, strong) NSString *callbackId;
@property (nonatomic, assign) BOOL isSigningIn;
@property (nonatomic, strong) NSArray *additionalScopes;

- (void)pluginInitialize;
- (void)handleOpenURL:(NSNotification*)notification;
- (void)handleOpenURLWithAppSourceAndAnnotation:(NSNotification*)notification;

- (void)isAvailable:(CDVInvokedUrlCommand*)command;
- (void)login:(CDVInvokedUrlCommand*)command;
- (void)trySilentLogin:(CDVInvokedUrlCommand*)command;
- (void)logout:(CDVInvokedUrlCommand*)command;
- (void)disconnect:(CDVInvokedUrlCommand*)command;
- (void)share_unused:(CDVInvokedUrlCommand*)command;

- (GIDSignIn*)getGIDSignInObject:(CDVInvokedUrlCommand*)command;
- (NSString*)reverseUrlScheme:(NSString*)scheme;
- (NSString*)getreversedClientId;

- (void)handleSignInResult:(GIDSignInResult *)result error:(NSError *)error;
- (void)handleSilentSignInResult:(GIDGoogleUser *)user error:(NSError *)error;
- (void)processUserResult:(GIDGoogleUser *)user;

@end
