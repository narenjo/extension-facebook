package extension.facebook;

import haxe.Json;
#if android
import extension.facebook.android.FacebookCFFI;
#elseif ios
import extension.facebook.ios.FacebookCFFI;
#elseif html5
import extension.facebook.html5.FacebookJS;
#end

@:enum
abstract AppRequestActionType(Int) to Int {
	var Send = 1;
	var AskFor = 2;
	var Turn = 3;
}
@:enum
abstract Filters(Int) to Int{
	var APP_USERS = 1;
	var APP_NON_USERS = 2;
}

typedef AppRequest = {
	@:optional var message : String;
	@:optional var title : String;
	@:optional var recipients : Array<String>;
	@:optional var objectId : String;
	@:optional var actionType : AppRequestActionType;
	@:optional var filters : Filters;
	@:optional var data : String;
}

typedef AppRequestResponse = {
	var id : String;
	@:optional var recipients : Array<String>;
	@:optional var to : Array<String>;
}

typedef ApplicationData = {
	var name : String;
	var namespace : String;
	var id : String;
	@:optional var category : String;
	@:optional var link : String;
}

typedef UserData = {
	var name : String;
	var id : String;
}

typedef FBObject = {
	var id : String;
	var application : ApplicationData;
	var to : UserData;
	var from : UserData;
	var message : String;
	var created_time : String;
}

class AppRequests {

	public static function sendObject(options : AppRequest, ?onAppRequestComplete : AppRequestResponse->Void = null, ?onAppRequestFail : String->Void) {
		#if (android || ios)
		if(onAppRequestComplete != null){
			setOnSendObjectCompleted(onAppRequestComplete);
		}
		if(onAppRequestFail != null){
			setOnSendObjectFailed(onAppRequestFail);
		}
		FacebookCFFI.appRequest(
			options.message,
			options.title,
			options.recipients,
			options.objectId,
			options.actionType,
			options.filters,
			options.data
		);
		#elseif html5
		var newOpt:GameRequestDialogParams = {
			method: "apprequests",
			message: options.message,
		};
		if(options.title != null){
			newOpt.title = options.title;
		}
		if(options.objectId != null){
			newOpt.object_id = options.objectId;
		}
		if(options.data != null){
			newOpt.data = options.data;
		}
		if(options.recipients != null){
			newOpt.to = options.recipients.join(",");
		}
		switch(options.actionType){
			case Send:
			newOpt.action_type = ActionType.Send;
			case AskFor:
			newOpt.action_type = ActionType.AskFor;
			case Turn:
			newOpt.action_type = ActionType.Turn;
		}
		switch(options.filters){
			case APP_USERS:
			newOpt.filters = extension.facebook.html5.Filters.app_user;
			case APP_NON_USERS:
			newOpt.filters = extension.facebook.html5.Filters.app_non_user;
		}
		trace(newOpt);
		FacebookJS.ui(newOpt, function (response:GameRequestDialogResponse) {
			trace(response);
			if (response.request != null && response.to != null && onAppRequestComplete != null) {
				onAppRequestComplete({id: response.request, to: response.to});
            }
			else if(onAppRequestFail != null) {
				onAppRequestFail(response.error_message);
			}
		});
		#end
	}

	public static function setOnSendObjectCompleted(fun : AppRequestResponse->Void) {
		#if (android || ios)
		FacebookCFFI.setOnAppRequestComplete(function (str) {
			fun(Json.parse(str));
		});
		#end
	}

	public static function setOnSendObjectFailed(fun : String->Void) {
		#if (android || ios)
		FacebookCFFI.setOnAppRequestFail(fun);
		#end
	}

	public static function deleteObject(
		f : Facebook,
		id : String,
		onComplete : FBObject->Void = null,
		onFail : Dynamic->Void = null
	) {
		f.delete(id, onComplete, onFail);
	}

	public static function getObject(
		f : Facebook,
		id : String,
		onComplete : FBObject->Void = null,
		onFail : Dynamic->Void = null
	) {
		f.get(id, onComplete, onFail);
	}


	public static function getObjectList(
		f : Facebook,
		onComplete : Array<FBObject>->Void = null,
		onFail : Dynamic->Void = null
	) {
		f.getAll("/me/apprequests", onComplete, onFail);
	}

}
