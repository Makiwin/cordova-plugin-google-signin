function GoogleSignIn() {
}

GoogleSignIn.prototype.isAvailable = function (callback) {
  cordova.exec(callback, null, "GoogleSignIn", "isAvailable", []);
};

GoogleSignIn.prototype.login = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GoogleSignIn", "login", [options]);
};

GoogleSignIn.prototype.trySilentLogin = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GoogleSignIn", "trySilentLogin", [options]);
};

GoogleSignIn.prototype.logout = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GoogleSignIn", "logout", []);
};

GoogleSignIn.prototype.disconnect = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GoogleSignIn", "disconnect", []);
};

GoogleSignIn.prototype.getSigningCertificateFingerprint = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GoogleSignIn", "getSigningCertificateFingerprint", []);
};

GoogleSignIn.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.googlesignin = new GoogleSignIn();
  return window.plugins.googlesignin;
};

cordova.addConstructor(GoogleSignIn.install);