function pluginSend(evt, params) {
	NATIVE && NATIVE.plugins && NATIVE.plugins.sendEvent &&
		NATIVE.plugins.sendEvent("UtilsPlugin", evt,
				JSON.stringify(params || {}));
}

function pluginOn(evt, next) {
	NATIVE && NATIVE.events && NATIVE.events.registerHandler &&
		NATIVE.events.registerHandler(evt, next);
}

function invokeCallbacks(list, clear) {
	// Pop off the first two arguments and keep the rest
	var args = Array.prototype.slice.call(arguments);
	args.shift();
	args.shift();

	// For each callback,
	for (var ii = 0; ii < list.length; ++ii) {
		var next = list[ii];

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

var Utils = Class(function () {
	var infoCB = [];

	this.init = function(opts) {
		logger.log("{utils} Registering for events on startup");

		pluginOn("deviceInfo", function(evt) {
			logger.log("{utils} Device Info Received:", JSON.stringify(evt));

			invokeCallbacks(infoCB, true, evt);
		});
	}
	
	this.shareText = function(message, url) {
		logger.log("{utils} Sharing Love");

		var parameters = {"message":message,"url":url};

		pluginSend("shareText", parameters);
	}

	this.getDevice = function(next) {
		logger.log("{utils} Getting Device Details");

		infoCB.push(next);

		pluginSend("getDevice");
	}

	this.logIt = function(stringData){
		logger.log("{utils} LogIT: "+ stringData+" |||");

		pluginSend("logIt",{"message":stringData});
	}

});

exports = new Utils();