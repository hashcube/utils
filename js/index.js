/* global NATIVE, logger, device, navigator, CONFIG */

/* jshint ignore: start */
import device;
/* jshint ignore: end */

exports = new (Class(function () {
  'use strict';

  var debug = false,
    cb_info = [],
    cb_jailbreak = [],
    cb_advt = [],
    cb_shared_app = [],
    cb_notif_enable_popup = [],
    cb_notif_enable_status = [],
    pluginSend = function (evt, params) {
      NATIVE.plugins.sendEvent('UtilsPlugin', evt,
          JSON.stringify(params || {}));
    },
    pluginOn = function (evt, next) {
      NATIVE.events.registerHandler(evt, next);
    },
    log = function () {
      var msg = '{utils} ';

      if (debug) {
        msg += Array.prototype.join.call(arguments, ' ');
        logger.log(msg);
      }
    },
    invokeCallbacks = function (list) {
      // Pop off the first two arguments and keep the rest
      var args = Array.prototype.splice.call(arguments, 2),
        len = list.length,
        i, next;

      // For each callback,
      for (i = 0; i < len; ++i) {
        next = list.pop();

        // If callback was actually specified,
        if (next) {
          // Run it
          next.apply(null, args);
        }
      }
      list.length = 0;
    },
    cb_installed_apps,
    cb_app_found;

  this.init = function () {
    logger.log('Register for events');

    pluginOn('deviceInfo', function (evt) {
      log('Device info received:', JSON.stringify(evt));

      invokeCallbacks(cb_info, true, evt);
    });

    pluginOn('utilsJailBroken', function (evt) {
      log('isJailBroken:', JSON.stringify(evt));

      invokeCallbacks(cb_jailbreak, true, evt.jb);
    });

    pluginOn('utilsAdvertisingId', function (evt) {
      log('Advertising ID received:', JSON.stringify(evt));

      invokeCallbacks(cb_advt, true, evt.id, evt.limit_tracking);
    });

    pluginOn('sharedWithApp', function (evt) {
      log('sharedWithApp:', JSON.stringify(evt));

      invokeCallbacks(cb_shared_app, true, evt.sharedApp);
    });

    pluginOn('performActionForShortcutItem', function (evt) {
      pluginSend('logIt', {
        'message':
          "Error in 3DTouch => performActionForShortcutItem called. Please overwrite in the application"
        });
    });

    pluginOn('SettingsOpened', function () {
      invokeCallbacks(cb_notif_enable_popup);
    });

    pluginOn('NotificationEnabledStatus', function (evt) {
      invokeCallbacks(cb_notif_enable_status, true, evt.enabled);
    });

    pluginOn('AppsInstalled',  function (evt) {
      log("installed_app data is: " + evt.apps);
      var app_data = JSON.parse(evt.apps);

      cb_installed_apps(app_data);
    });

    pluginOn('AppFound', function (evt) {
      cb_app_found(evt.found);
    });
  };

  this.shareText = function (message, url, callback) {
    var parameters = {'message': message, 'url': url};

    log('Sharing text');
    cb_shared_app.push(callback)

    pluginSend('shareText', parameters);
  };

  this.showEnableNotificationPopup = function (title, message,
    open_btn, cancel_btn, callback) {
    var parameters = {'title': title, 'message': message,
      'open_btn_title': open_btn, 'cancel_btn_title': cancel_btn};

    cb_notif_enable_popup.push(callback)
    pluginSend('showEnableNotificationPopup', parameters);
  };

  this.getNotificationEnabledStatus = function (callback) {
    cb_notif_enable_status.push(callback);
    pluginSend('getNotificationEnabledStatus');
  };

  this.requestForReview = function () {
    log('requesting for Review');

    pluginSend('requestForReview');
  };

  this.getDeviceInfo = function (next) {
    log('Getting device details');

    if (!device.isMobileNative) {
      next({
        type: 'browser',
        language: navigator.language,
        os: navigator.platform,
        device: navigator.userAgent,
        versionNumber: CONFIG.version,
        store: 'web'
      });
    } else {
      cb_info.push(next);
      pluginSend('getDeviceInfo');
    }
  };

  this.logIt = function (stringData) {
    log('Log it: ' + stringData);

    pluginSend('logIt', {'message': stringData});
  };

  this.isJailBroken = function (next) {
    log('isJailBroken check');

    cb_jailbreak.push(next);

    pluginSend('isJailBroken');
  };

  this.getAdvertisingId = function (next) {
    log('Getting advertising ID');

    if (!device.isMobileNative) {
      // return a random number between 0 and 1000 and doNotTrack info
      next(Math.floor(Math.random() * 1000), navigator.doNotTrack);
    } else {
      cb_advt.push(next);
      pluginSend('getAdvertisingId');
    }
  };

  this.updateShortcutItems = function (jsonObject) {
    log('Updating shortcut Items');

    pluginSend('updateShortcutItems', jsonObject);
  };

  this.getInstalledApps = function (cb) {
    log('get other installed apps');

    cb_installed_apps = cb;
    pluginSend('getInstalledApps');
  };

  this.isAppInstalled = function (identifier, cb) {
    log("is app installed: " + identifier);
    cb_app_found = cb;
    pluginSend('isAppInstalled', {
      identifier: identifier
    });
  };

}))();
