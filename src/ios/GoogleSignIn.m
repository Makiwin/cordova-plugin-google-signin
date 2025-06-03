#import "AppDelegate.h"
#import "objc/runtime.h"
#import "GoogleSignIn.h"

@implementation GoogleSignIn

- (void)pluginInitialize
{
    NSLog(@"GoogleSignIn pluginInitizalize");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:CDVPluginHandleOpenURLNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURLWithAppSourceAndAnnotation:) name:CDVPluginHandleOpenURLWithAppSourceAndAnnotationNotification object:nil];
}

- (void)handleOpenURL:(NSNotification*)notification
{
    // no need to handle this handler, we dont have an sourceApplication here, which is required by GIDSignIn handleURL
}

- (void)handleOpenURLWithAppSourceAndAnnotation:(NSNotification*)notification
{
    NSMutableDictionary * options = [notification object];

    NSURL* url = options[@"url"];

    NSString* possibleReversedClientId = [url.absoluteString componentsSeparatedByString:@":"].firstObject;

    if ([possibleReversedClientId isEqualToString:self.getreversedClientId] && self.isSigningIn) {
        self.isSigningIn = NO;
        [[GIDSignIn sharedInstance] handleURL:url];
    }
}

// If this returns false, you better not call the login function because of likely app rejection by Apple,
// see https://code.google.com/p/google-plus-platform/issues/detail?id=900
// Update: should be fine since we use the GoogleSignIn framework instead of the GooglePlus framework
- (void) isAvailable:(CDVInvokedUrlCommand*)command {
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) login:(CDVInvokedUrlCommand*)command {
    GIDSignIn *signIn = [self getGIDSignInObject:command];
    if (signIn != nil) {
        if (_additionalScopes != nil && _additionalScopes.count > 0) {
            [signIn signInWithPresentingViewController:self.viewController
                                                 hint:nil
                                    additionalScopes:_additionalScopes
                                          completion:^(GIDSignInResult * _Nullable result, NSError * _Nullable error) {
                [self handleSignInResult:result error:error];
            }];
        } else {
            [signIn signInWithPresentingViewController:self.viewController completion:^(GIDSignInResult * _Nullable result, NSError * _Nullable error) {
                [self handleSignInResult:result error:error];
            }];
        }
    }
}

/** Get Google Sign-In object
 @date July 19, 2015
 @date updated June 03, 2025 (@author Makiwin)
 */
- (void) trySilentLogin:(CDVInvokedUrlCommand*)command {
    GIDSignIn *signIn = [self getGIDSignInObject:command];
    if (signIn != nil) {
        [signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
            [self handleSilentSignInResult:user error:error];
        }];
    }
}

/** Get Google Sign-In object
 @date July 19, 2015
 @date updated June 03, 2025 (@author Makiwin)
 @date updated for GoogleSignIn 7.0.0
 */
- (GIDSignIn*) getGIDSignInObject:(CDVInvokedUrlCommand*)command {
    _callbackId = command.callbackId;
    NSDictionary* options = command.arguments[0];
    NSString *reversedClientId = [self getreversedClientId];

    if (reversedClientId == nil) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not find REVERSED_CLIENT_ID url scheme in app .plist"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
        return nil;
    }

    NSString *clientId = [self reverseUrlScheme:reversedClientId];

    NSString* scopesString = options[@"scopes"];
    NSString* serverClientId = options[@"webClientId"];
    NSString *loginHint = options[@"loginHint"];
    BOOL offline = [options[@"offline"] boolValue];
    NSString* hostedDomain = options[@"hostedDomain"];

    // Configure GIDSignIn
    GIDConfiguration *config;
    
    if (serverClientId != nil && offline) {
        config = [[GIDConfiguration alloc] initWithClientID:clientId
                                           serverClientID:serverClientId];
    } else {
        config = [[GIDConfiguration alloc] initWithClientID:clientId];
    }
    
    // Set hosted domain separately if provided
//    if (hostedDomain != nil) {
//        config.hostedDomain = hostedDomain;
//    }

    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    signIn.configuration = config;

    // Set additional scopes if provided - these need to be set during sign-in call
    if (scopesString != nil) {
        NSArray* scopes = [scopesString componentsSeparatedByString:@" "];
        // Store scopes for use in sign-in methods
        _additionalScopes = scopes;
    }

    return signIn;
}

- (void)handleSignInResult:(GIDSignInResult *)result error:(NSError *)error {
    if (error) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    } else {
        GIDGoogleUser *user = result.user;
        [self processUserResult:user];
    }
}

- (void)handleSilentSignInResult:(GIDGoogleUser *)user error:(NSError *)error {
    if (error) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    } else {
        [self processUserResult:user];
    }
}

- (void)processUserResult:(GIDGoogleUser *)user {
    NSString *email = user.profile.email;
    NSString *idToken = user.idToken.tokenString;
    NSString *accessToken = user.accessToken.tokenString;
    NSString *refreshToken = user.refreshToken.tokenString ? : @"";
    NSString *userId = user.userID;
    // NSString *serverAuthCode = user.accessToken != nil ? user.serverAuthCode : @"";
    NSURL *imageUrl = [user.profile imageURLWithDimension:120]; // TODO pass in img size as param, and try to sync with Android
    
    NSDictionary *result = @{
                   @"email"           : email,
                   @"idToken"         : idToken,
                   // @"serverAuthCode"  : serverAuthCode,
                   @"accessToken"     : accessToken,
                   @"refreshToken"    : refreshToken,
                   @"userId"          : userId,
                   @"displayName"     : user.profile.name       ? : [NSNull null],
                   @"givenName"       : user.profile.givenName  ? : [NSNull null],
                   @"familyName"      : user.profile.familyName ? : [NSNull null],
                   @"imageUrl"        : imageUrl ? imageUrl.absoluteString : [NSNull null],
                   };

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
}

- (NSString*) reverseUrlScheme:(NSString*)scheme {
  NSArray* originalArray = [scheme componentsSeparatedByString:@"."];
  NSArray* reversedArray = [[originalArray reverseObjectEnumerator] allObjects];
  NSString* reversedString = [reversedArray componentsJoinedByString:@"."];
  return reversedString;
}

- (NSString*) getreversedClientId {
  NSArray* URLTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];

  if (URLTypes != nil) {
    for (NSDictionary* dict in URLTypes) {
      NSString *urlName = dict[@"CFBundleURLName"];
      if ([urlName isEqualToString:@"REVERSED_CLIENT_ID"]) {
        NSArray* URLSchemes = dict[@"CFBundleURLSchemes"];
        if (URLSchemes != nil) {
          return URLSchemes[0];
        }
      }
    }
  }
  return nil;
}

- (void) logout:(CDVInvokedUrlCommand*)command {
  [[GIDSignIn sharedInstance] signOut];
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"logged out"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
  [[GIDSignIn sharedInstance] disconnectWithCompletion:^(NSError * _Nullable error) {
      NSString *message = error ? error.localizedDescription : @"disconnected";
      CDVCommandStatus status = error ? CDVCommandStatus_ERROR : CDVCommandStatus_OK;
      CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:status messageAsString:message];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}

- (void) share_unused:(CDVInvokedUrlCommand*)command {
  // for a rainy day.. see for a (limited) example https://github.com/vleango/GooglePlus-PhoneGap-iOS/blob/master/src/ios/GPlus.m
}

@end
