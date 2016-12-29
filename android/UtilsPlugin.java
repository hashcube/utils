package com.tealeaf.plugin.plugins;

import com.tealeaf.logger;
import com.tealeaf.TeaLeaf;
import com.tealeaf.EventQueue;
import com.tealeaf.plugin.IPlugin;

import android.os.AsyncTask;
import android.os.Bundle;
import android.app.Activity;
import android.content.Intent;
import android.content.Context;
import android.net.Uri;
import android.content.pm.PackageManager;
import android.content.pm.PackageInfo;
import android.content.pm.ShortcutManager;
import android.content.pm.ShortcutInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.drawable.Icon;
import com.google.android.gms.ads.identifier.AdvertisingIdClient;
import com.google.android.gms.ads.identifier.AdvertisingIdClient.Info;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Locale;

import org.json.JSONException;
import org.json.JSONObject;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.support.v4.app.NotificationManagerCompat;

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
		long installDate;

		public DeviceEvent(Context context) {
			super("deviceInfo");
			PackageManager packageManager = context.getPackageManager();
			String packageName = context.getPackageName();
			String myVersionName = "not available";
			long firstInstallTime = -1;


			try {
				PackageInfo packageInfo = packageManager.getPackageInfo(packageName, 0);
				myVersionName = packageInfo.versionName;
				//dividing by thousand to convert milliseconds to seconds
				firstInstallTime = packageInfo.firstInstallTime;
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
			this.installDate = firstInstallTime;
			this.language = Locale.getDefault().getLanguage();

			try {
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

	public class ShortcutEvent extends com.tealeaf.event.Event {
		String val;

		public ShortcutEvent(String val) {
			super("performActionForShortcutItem");

			this.val = val;
		}
	}

	public class SettingsOpened extends com.tealeaf.event.Event {
		public SettingsOpened() {
			super("SettingsOpened");
		}
	}

	public class NotificationEnabledStatus extends com.tealeaf.event.Event {
		boolean enabled;

		public NotificationEnabledStatus(boolean enabled) {
			super("NotificationEnabledStatus");
			this.enabled = enabled;
		}
	}

	public UtilsPlugin() {
	}

	public void onCreateApplication(Context applicationContext) {
		_context = applicationContext;
	}

	public void onCreate(Activity activity, Bundle savedInstanceState) {
		_activity = activity;
		onNewIntent(activity.getIntent());
	}

	public void onResume() {
		// Track app active events
	}

	public void onRenderResume() {
	}

	public void onStart() {
	}

	public void onFirstRun() {
	}

	public void onPause() {
	}

	public void onRenderPause() {
	}

	public void onStop() {
	}

	public void onDestroy() {
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

		new Thread(new Runnable() {
			public void run() {
				String adId = "";
				boolean isLAT = true;

				try {
					if(android.os.Build.MANUFACTURER.equals("Amazon")) {
						adId = android.os.Build.SERIAL;
					}
					final Info adInfo = AdvertisingIdClient.getAdvertisingIdInfo(_context);
					isLAT = adInfo.isLimitAdTrackingEnabled();
					adId = adInfo.getId();
				} catch (Exception e) {
					//either google play services not available/old client
					logger.log("{utils-native} Error trying to retrieve advertising details" + e.getMessage());
				}
				EventQueue.pushEvent(new AdvertisingIdEvent(adId, isLAT));
			}
		}).start();
	}

	public void onNewIntent(Intent gameIntent) {
		logger.log("{utils-native} Inside onNewIntent");
		if (gameIntent.getAction() == TeaLeaf.ACTION_SHORTCUT) {
			logger.log("{utils-native} pushing shortcut action event");
			EventQueue.pushEvent(new ShortcutEvent(gameIntent.getExtras().getString(TeaLeaf.SHORTCUT_KEY)));
		}
	}

	public void openAppSettings() {
		Uri packageURI = Uri.parse("package:" + _context.getPackageName());
		Intent intent = new Intent("android.settings.APPLICATION_DETAILS_SETTINGS", packageURI);
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		_context.startActivity(intent);
	}

	public void showEnableNotificationPopup(String params) {
		try {
			String title = "", message = "", openBtnTitle = "";
			JSONObject data = new JSONObject(params);
			Iterator<?> keys = data.keys();
			while( keys.hasNext() ){
				String key = (String)keys.next();
				Object o = data.get(key);
				if(key.equals("title")){
					title = (String) o;
					continue;
				}
				if(key.equals("message")){
					message = (String) o;
					continue;
				}
				if(key.equals("open_btn_title")){
					openBtnTitle = (String) o;
					continue;
				}
			}

			final String ftitle = title;
			final String fmessage = message;
			final String fopenBtnTitle = openBtnTitle;
			_activity.runOnUiThread(new Runnable() {
				public void run() {
					new AlertDialog.Builder(_activity)
					.setTitle(ftitle)
					.setMessage(fmessage)
					.setPositiveButton(fopenBtnTitle, new DialogInterface.OnClickListener() {
						public void onClick(DialogInterface dialog, int whichButton) {
							EventQueue.pushEvent(new SettingsOpened());
							openAppSettings();
					    }})
					 .show();
				}
			});
		} catch(Exception e) {
			logger.log("{utils-native} Exception" + e);
		}
	}

	public void getNotificationEnabledStatus(String params) {
		logger.log("{utils-native} getNotificationEnabledStatus java");
		NotificationManagerCompat n = NotificationManagerCompat.from(_activity);
		EventQueue.pushEvent(new NotificationEnabledStatus(n.areNotificationsEnabled()));
	}

	public void updateShortcutItems(String params) {
		logger.log("{utils-native} Inside updateShortcutItems");
		if (android.os.Build.VERSION.SDK_INT < 25) {
			return;
		}

		try {
			ShortcutManager shortcutManager = _activity.getSystemService(ShortcutManager.class);
			JSONObject shortcuts = new JSONObject(params);
			Iterator<?> keys = shortcuts.keys();
			List<ShortcutInfo> shortcutList = new ArrayList<ShortcutInfo>();

			while (keys.hasNext()) {
				String key = (String)keys.next();
				JSONObject data = shortcuts.getJSONObject(key);
				String title = data.getString("title");
				logger.log("{utils-native} adding shortcut for : " + key);

				Intent shortcutIntent = _context.getPackageManager().getLaunchIntentForPackage(_context.getPackageName());
				shortcutIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
				shortcutIntent.setAction(TeaLeaf.ACTION_SHORTCUT);
				shortcutIntent.putExtra(TeaLeaf.SHORTCUT_KEY, key);

				ShortcutInfo shortcut = new ShortcutInfo.Builder(_activity, key)
                                	.setShortLabel(title)
                                	.setLongLabel(title)
					.setIcon(Icon.createWithResource(_context, _context.getResources().getIdentifier("shortcut_" +
						 data.getString("icon"), "drawable", _context.getPackageName())))
                                	.setIntent(shortcutIntent)
					.build();
				shortcutList.add(shortcut);
			}

			shortcutManager.setDynamicShortcuts(shortcutList);
		} catch (Exception ex) {
			logger.log("{utils-native} Exception creating shortcut... " + ex);
		}
	}
}
