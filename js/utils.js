function pluginSend(evt, params) {
	NATIVE.plugins.sendEvent("UtilsPlugin", evt,
			JSON.stringify(params || {}));
}

function pluginOn(evt, next) {
	NATIVE.events.registerHandler(evt, next);
}

function invokeCallbacks(list, clear) {
	// Pop off the first two arguments and keep the rest
	var args = Array.prototype.splice.call(arguments, 2),
	    i = 0,
	    len = list.length,
	    next;

	// For each callback,
	for (i = 0; i < len; ++i) {
		next = list[i];

		// If callback was actually specified,
		if (next) {
			// Run it
			next.apply(null, args);
		}
	}

	// If asked to clear the list too,
	if (clear) {
		list.length = 0;
	}
}

exports = new (Class(function () {
	var infoCB = [],
	    jbCB = [],
	    adIdCB = [];

	this.init = function(opts) {
		logger.log("{utils} Registering for events on startup");

		pluginOn("deviceInfo", function(evt) {
			logger.log("{utils} Device Info Received:", JSON.stringify(evt));

			invokeCallbacks(infoCB, true, evt);
		});

		pluginOn("utilsJailBroken", function(evt) {
			logger.log("{utils} isJailBroken:", JSON.stringify(evt));

			invokeCallbacks(jbCB, true, evt.jb);
		});

		pluginOn("utilsAdvertisingId", function(evt) {
			invokeCallbacks(adIdCB, true, evt.id, evt.limit_tracking);
		});
	}

	this.shareText = function(message, url) {
		logger.log("{utils} Sharing Love");

		var parameters = {"message":message,"url":url};

		pluginSend("shareText", parameters);
	}

	this.getDeviceInfo = function(next) {
		logger.log("{utils} Getting Device Details");

		infoCB.push(next);

		pluginSend("getDeviceInfo");
	}

	this.logIt = function(stringData) {
		logger.log("{utils} LogIT: "+ stringData+" |||");

		pluginSend("logIt",{"message":stringData});
	}

	this.isJailBroken = function(next) {
		logger.log("{utils} isJailBroken check");

		jbCB.push(next);

		pluginSend("isJailBroken");
	}

	this.getAdvertisingId = function(next) {
		adIdCB.push(next);
		pluginSend("getAdvertisingId");
	}

}))();
