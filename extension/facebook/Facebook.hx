
package extension.facebook;

#if android
import extension.facebook.android.FacebookCallbacks;
import extension.facebook.android.FacebookCFFI;
#elseif ios
import extension.facebook.ios.FacebookCFFI;
#elseif html5
import extension.facebook.html5.FacebookJS;
import haxe.Timer;
#end

import extension.util.task.*;
import flash.Lib;
import flash.net.URLRequest;
import haxe.Json;
#if (cpp || neko)
import sys.net.Host;
import sys.net.Socket;
#end

#if cpp
import cpp.vm.Thread;
#elseif neko
import neko.vm.Thread;
#end

@:enum
abstract PermissionsType(Int) {
	var Publish = 0;
	var Read = 1;
}

class Facebook extends TaskExecutor {

	static var initted = false;
	public var accessToken : String;

	private var initCallback:Bool->Void;
	private static var instance:Facebook=null;
	private static var firstTime:Bool = true;

	public static function getInstance():Facebook{
		if(instance==null) instance = new Facebook();
		return instance;
	}

	private function new() {
		accessToken = "";
		super();
	}

	public function init(initCallback:Bool->Void) {
		if (!initted) {
			#if (android || ios)
			this.initCallback = initCallback;
			FacebookCFFI.init(this.setAuthToken);
			#elseif html5
			this.initCallback = initCallback;
			var loadingTimer = new Timer(500);
			var maxTries = 10;
			var tries = 0;
			loadingTimer.run = function (){

				var isLoaded = untyped window.fbLoaded;
				if(isLoaded) {
					loadingTimer.stop();
					FacebookJS.getLoginStatus(function(response){
						if (response.status == Status.CONNECTED) {
							this.setAuthToken(response.authResponse.accessToken);
						}
						else {
							this.setAuthToken("");
						}
					});
				}
				if(tries > maxTries){
					loadingTimer.stop();
				}
				tries++;
			}
			#end
		}
	}

	public function setAuthToken(token) {
		if (token != "") {
			initted = true;
		}
		this.accessToken = token;
		if (firstTime && this.initCallback != null) {
			firstTime = false;
			this.initCallback(true);
		}
	}
public function getToken():String{
	#if android
	return FacebookCFFI.getCurrentAccessToken();
	#end
	return "";
}
	public function login(
		type : PermissionsType,
		permissions : Array<String>,
		onComplete : Void->Void,
		onCancel : Void->Void,
		onError : String->Void
	) {

		var fonComplete = function() {
			addTask(new CallTask(onComplete));
		}

		var fOnCancel = function() {
			addTask(new CallTask(onCancel));
		}

		var fOnError = function(error) {
			addTask(new CallStrTask(onError, error));
		}

		#if (android || ios)

		FacebookCFFI.setOnLoginSuccessCallback(fonComplete);
		FacebookCFFI.setOnLoginCancelCallback(fOnCancel);
		FacebookCFFI.setOnLoginErrorCallback(fOnError);

		FacebookCFFI.logInWithReadPermissions(permissions);

		#elseif html5
		var opts:LoginOptions = {};
		if(permissions.length > 0){
			opts.scope = permissions.join(",");
		}
		FacebookJS.login(function(response:StatusResponse){
			if (response.status == Status.CONNECTED) {
				this.setAuthToken(response.authResponse.accessToken);
				//Bug facebook logout
				var cookieName = "fblo_" + untyped window.fbAppId;
				if(js.Cookie.exists(cookieName)){
					js.Cookie.remove(cookieName);
				}
				fonComplete();
            }
			else if(response.status == Status.NOT_AUTHORIZED || response.status == Status.UNKNOWN){
				fOnCancel();
			}
			else {
				fOnError(response.status);
			}
		}, opts);
		#elseif (cpp || neko)

		var appID = Sys.getEnv("FACEBOOK_APP_ID");
		var redirectUri = Sys.getEnv("FACEBOOK_REDIRECT_URI");
		var url = 'https://www.facebook.com/dialog/oauth?client_id=$appID&redirect_uri=$redirectUri';

		Thread.create(function() {
			var s = new Socket();
			s.bind(new Host("localhost"), 8100);
			s.listen(1);
			var stopSrvLoop = false;
			do {
				var result = Socket.select([s], [], [], 0.5);
				if (result.read.length>0) {
					var c = s.accept();
					var str = null;
					var error = true;
					while (str!="") {
						str = c.input.readLine();
						if (~/GET \/+/.match(str)) {
							str = str.split(" ")[1];
							str = str.substr(2);
							for (v in str.split("&")) {
								var arr = v.split("=");
								if (arr[0]=="access_token") {
									this.accessToken = arr[1];
									addTask(new CallTask(onComplete));
									error = false;
								}
							}
						}
					}
					if (error) {
						addTask(new CallStrTask(fOnError, "Error"));
					}
					c.write(error?HTMLAssets.getErrorHTML():HTMLAssets.getSuccessHTML());
					c.close();
					stopSrvLoop = true;
				}
			} while (!stopSrvLoop);
			s.close();
		});

		Lib.getURL(new URLRequest(url));

		#end

	}

	public function logout() {
		#if (android || iphone)
		FacebookCFFI.logout();
		#elseif html5
		FacebookJS.logout();
		#end
	}

	function prependSlash(str : String) : String {
		if (str.charAt(0)=="/") {
			return str;
		}
		return "/" + str;
	}

	function send(
		method : String,
		resource : String,
		onComplete : Dynamic->Void = null,
		parameters : Map<String, String> = null,
		onError : Dynamic->Void = null
	) : Void {

		if (onComplete==null) {
			onComplete = function(s) {};
		}
		if (parameters==null) {
			parameters = new Map<String, String>();
		}
		if (onError==null) {
			onError = function(s) {};
		}
		parameters.set("redirect", "false");
		#if ios
		FacebookCFFI.setOnGraphRequestComplete(function (str) {
			onComplete(Json.parse(str));
		});
		FacebookCFFI.setOnGraphRequestFail(onError);

		var aParameters = [
			for(key in parameters.keys()){
				key + "||" + parameters.get(key);
			}
		];
		FacebookCFFI.graphRequest(
			prependSlash(resource),
			aParameters,
			method
		);
		#elseif android
		FacebookCFFI.graphRequest(
			prependSlash(resource),
			parameters,
			method,
			function(x) {
				try { 
					var parsed = Json.parse(x);
					onComplete(parsed);
				} catch(error:String) { trace(error, x); }
			},
			function(x) {
				try { 
					var parsed = Json.parse(x);
					onError(parsed);
				} catch(error:String) { trace(error, x); }	
			}
		);
		#elseif html5
		FacebookJS.api(prependSlash(resource), method, parameters, function(response:Dynamic){
			if(response == null || response.error){
				onError(response);
			}
			else {
				onComplete(response);
			}
		});
		#else
		parameters.set("access_token", accessToken);
		var fGet = RestClient.getAsync.bind(_);
		var fPost = RestClient.postAsync.bind(_);
		var fDelete = RestClient.deleteAsync.bind(_);
		var f;
		switch (method){
			case "POST" : f = fPost;
			case "DELETE" : f = fDelete;
			default : f = fGet;
		}
		f(
			"https://graph.facebook.com/v4.0"+prependSlash(resource),
			function(x) {
				try { 
					var parsed = Json.parse(x);
					onComplete(parsed);
				} catch(error:String) { trace(error, x); }
			},
			parameters,
			function(x) {
				try { 
					var parsed = Json.parse(x);
					onError(parsed);
				} catch(error:String) { trace(error, x); }	
			}
		);
		#end
	}

	public function delete(
		resource : String,
		onComplete : Dynamic->Void = null,
		parameters : Map<String, String> = null,
		onError : Dynamic->Void = null
	) : Void {

		send("DELETE", resource, onComplete, parameters, onError);
	}

	public function get(
		resource : String,
		onComplete : Dynamic->Void = null,
		parameters : Map<String, String> = null,
		onError : Dynamic->Void = null
	) : Void {

		send("GET", resource, onComplete, parameters, onError);
	}

	public function post(
		resource : String,
		onComplete : Dynamic->Void = null,
		parameters : Map<String, String> = null,
		onError : Dynamic->Void = null
	) : Void {

		send("POST", resource, onComplete, parameters, onError);
	}

	// get the full list of some resource (manages paging)
	public function getAll<T>(
		resource : String,
		onComplete : Array<T>->Void,
		parameters : Map<String, String> = null,
		onError : Dynamic->Void = null,
		acum : Array<T> = null,
		after : String = null) {

		if (acum==null) {
			acum = [];
		}
		if (parameters==null) {
			parameters = new Map<String, String>();
		}
		if (after!=null) {
			parameters.set("after", after);
		}
		get(
			prependSlash(resource),
			function (data) {
				for (it in cast(data.data, Array<Dynamic>)) {
					acum.push(it);
				}
				if (data.paging!=null && data.paging.cursors!=null && data.paging.cursors.after!=null) {
					getAll(resource, onComplete, onError, acum, data.paging.cursors.after);
				} else {
					onComplete(acum);
				}
			},
			parameters,
			onError
		);

	}
}
