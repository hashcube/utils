package com.tealeaf.plugin.plugins;

import com.tealeaf.logger;
import com.tealeaf.TeaLeaf;
import com.tealeaf.EventQueue;
import com.tealeaf.plugin.IPlugin;

import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Build.*;
import android.os.Build.VERSION.*;
import android.app.Activity;
import android.content.Intent;
import android.content.Context;
import android.net.Uri;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import com.google.android.gms.ads.identifier.AdvertisingIdClient;
import com.google.android.gms.ads.identifier.AdvertisingIdClient.Info;

import java.util.Iterator;
import java.util.Locale;

import org.json.JSONException;
import org.json.JSONObject;

public class UtilsPlugin implements IPlugin {
	Context _context;
	Activity _activity;

	public class DeviceEvent extends com.tealeaf.event.Event {
		String type;
		String os;
		String device;
		String versionNumber;
		String store;
		String language;

		public DeviceEvent(Context context) {
			super("deviceInfo");
			PackageManager packageManager = context.getPackageManager();
			String packageName = context.getPackageName();
			String myVersionName = "not available";
			try {
				myVersionName = packageManager.getPackageInfo(packageName, 0).versionName;
			} catch (PackageManager.NameNotFoundException e) {
				e.printStackTrace();
			}
			this.type = "android";
			if (android.os.Build.BRAND.equalsIgnoreCase("Amazon")) {
				this.type = "kindle";
			}
			this.os = android.os.Build.VERSION.RELEASE;
			this.device = android.os.Build.MODEL;
			this.versionNumber = myVersionName;
			this.language = Locale.getDefault().getLanguage();

			try{
				Bundle meta = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA).metaData;
				if (meta != null) {
					this.store = meta.get("INSTALL_STORE").toString();
				}
			} catch (Exception e) {
				logger.log("{utils-native} Exception on start:", e.getMessage());
			}
			if(this.store.equals("nokia")){
				this.os = "Android4.1.2";
				this.device = "NokiaX";
				this.type = "nokia";
			}
		}
	}

	public class AdvertisingIdEvent extends com.tealeaf.event.Event {
		String id;
		int limit_tracking;

		public AdvertisingIdEvent(String id, boolean limit) {
			super("utilsAdvertisingId");

			this.id = id;
			this.limit_tracking = limit? 1: 0;
		}
	}

	public UtilsPlugin() {
	}

	public void onCreateApplication(Context applicationContext) {
		_context = applicationContext;
	}

	public void onCreate(Activity activity, Bundle savedInstanceState) {
		_activity = activity;
	}

	public void onResume() {
		// Track app active events
	}

	public void onStart() {
	}

	public void onPause() {
	}

	public void onStop() {
	}

	public void onDestroy() {
	}

	public void onNewIntent(Intent intent) {
	}

	public void setInstallReferrer(String referrer) {
	}

	public void onActivityResult(Integer request, Integer result, Intent data) {
	}

	public boolean consumeOnBackPressed() {
		return true;
	}

	public void onBackPressed() {
	}

	public void logError(String errorDesc) {
		logger.log("{utils-native} logError "+ errorDesc);
	}

	public void getDeviceInfo(String dummy) {
		EventQueue.pushEvent(new DeviceEvent(_context));
	}

	public void logIt(String json) {
		String shareText = "";
		try {
			JSONObject ogData = new JSONObject(json);
			Iterator<?> keys = ogData.keys();
			while( keys.hasNext() ){
				String key = (String)keys.next();
				Object o = ogData.get(key);
				if(key.equals("message")){
					shareText = (String) o;
					continue;
				}
			}
		} catch(JSONException e) {
			logger.log("{utils-native} Error in Params of logIt because "+ e.getMessage());
		}
		logger.log("{utils-native} LOGIT = "+ shareText);
	}

	public void shareText(String param) {
		logger.log("{utils-native} Inside shareText");
		String shareText = "", shareURL = "";
		try {
			JSONObject ogData = new JSONObject(param);
			Iterator<?> keys = ogData.keys();
			while( keys.hasNext() ){
				String key = (String)keys.next();
				Object o = ogData.get(key);
				if(key.equals("message")){
					shareText = (String) o;
					continue;
				}
				if(key.equals("url")){
					shareURL = (String) o;
					continue;
				}
			}
		} catch(JSONException e) {
			logger.log("{utils-native} Error in Params of shareText because "+ e.getMessage());
		}
		Intent sendIntent = new Intent();
		sendIntent.setAction(Intent.ACTION_SEND);
		sendIntent.putExtra(Intent.EXTRA_TEXT, shareText + " : (" + shareURL + ") #sudoku #sudokuquest");
		sendIntent.setType("text/plain");
		_activity.startActivity(Intent.createChooser(sendIntent, "Spread the word"));
	}

	public void getAdvertisingId(String dummy) {

		AsyncTask<Void, Void, String> task = new AsyncTask<Void, Void, String>() {
			@Override
				protected String doInBackground(Void... params) {
					String advertiseId = "";
					boolean limitAdTrackEnabled = true;
					try {
						final Info adInfo = AdvertisingIdClient.getAdvertisingIdInfo(_context);
						limitAdTrackEnabled = adInfo.isLimitAdTrackingEnabled();
						advertiseId = adInfo.getId();
					} catch (Exception e) {
						//either google play services not available/old client
						logger.log("{utils-native} Error trying to retrieve advertising details" + e.getMessage());
					}
					EventQueue.pushEvent(new AdvertisingIdEvent(advertiseId, limitAdTrackEnabled));
					//dummy return
					return "";
				}
		};
		task.execute();
	}
}
