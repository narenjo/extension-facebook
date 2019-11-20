package extension.facebook.html5;

@:native("FB")
extern class FacebookJS {
    /**
    * The method FB.getAuthResponse() is a synchronous accessor for the current authResponse.
    * The synchronous nature of this method is what sets it apart from the other login methods.
    *
    * This method is similar in nature to FB.getLoginStatus(), but it returns just the authResponse object.
    */
    public function getAuthResponse(): haxe.extern.EitherType<AuthResponse , String>;

    /**
    * FB.getLoginStatus() allows you to determine if a user is
    * logged in to Facebook and has authenticated your app.
    *
    * @param callback function to handle the response.
    * @param roundtrip force a roundtrip to Facebook - effectively refreshing the cache of the response object
    */
    public static function getLoginStatus(callback:StatusResponse->Void, ?roundtrip:Bool): Void;

    /**
    * The method FB.init() is used to initialize and setup the SDK.
    *
    * @param params params for the initialization.
    */
    public static function init(params: InitParams): Void;

    /**
    * Use this function to log the user in
    *
    * Calling FB.login() results in the JS SDK attempting to open a popup window.
    * As such, this method should only be called after a user click event, otherwise
    * the popup window will be blocked by most browsers.
    *
    * @param callback function to handle the response.
    * @param options optional ILoginOption to add params such as scope.
    */
    public static function login(?callback:StatusResponse->Void, ?options:LoginOptions): Void;

    public static function api(path: String, ?method:String, ?params:Dynamic, ?callback:Dynamic->Void):Void;

    /**
    * @see https://developers.facebook.com/docs/sharing/reference/share-dialog
    */
    /**
     * @see https://developers.facebook.com/docs/games/services/gamerequests
     */
    @:overload(function(params: ShareDialogParams, ?callback:ShareDialogResponse->Void): Void {})
    @:overload(function(params: FeedDialogParams, ?callback:ShareDialogResponse->Void): Void {})
    public static function ui(params: GameRequestDialogParams, ?callback:GameRequestDialogResponse->Void): Void;

    /**
    * The method FB.logout() logs the user out of your site and, in some cases, Facebook.
    *
    * @param callback optional function to handle the response
    */
    public static function logout(?callback:StatusResponse->Void): Void;
}
extern typedef InitParams = {
    var appId : String;
    @:optional var version : String;
    @:optional var cookie : Bool;
    @:optional var status : Bool;
    @:optional var xfbml : Bool;
    @:optional var frictionlessRequests : Bool;
    @:optional var hideFlashCallback : Bool;
    @:optional var autoLogAppEvents : Bool;
}

extern typedef LoginOptions = {
    @:optional var auth_type : String;
    @:optional var scope : String;
    @:optional var return_scopes : Bool;
    @:optional var enable_profile_selector : Bool;
    @:optional var profile_selector_ids : String;
}

////////////////////////
//
//  RESPONSES
//
////////////////////////
@:enum extern abstract Status(String) from String to String {
	var CONNECTED = "connected";
    var AUTH_EXPIRED = "authorization_expired";
    var NOT_AUTHORIZED = "not_authorized";
    var UNKNOWN = "unknown";
}
extern typedef AuthResponse = {
    var accessToken : String;
    var expiresIn : Float;
    var signedRequest : String;
    var userID : String;
    @:optional var grantedScopes : String;
    @:optional var reauthorize_required_in : Float;
}
extern typedef StatusResponse = {
    var status: Status;//'authorization_expired' | 'connected' | 'not_authorized' | 'unknown';
    var authResponse : AuthResponse;
}
extern typedef DialogResponse = {
    @:optional var error_code : Float;
    @:optional var error_message : String;
}
extern typedef ShareDialogResponse = {
    > DialogResponse,
    var post_id : String;
}
extern typedef GameRequestDialogResponse = {
    > DialogResponse,
    var request : String;
    var to : Array<String>;
}

////////////////////////
//
//  DIALOGS
//
////////////////////////

extern typedef DialogParams = {
    @:optional var app_id : String;
    @:optional var redirect_uri : String;
    @:optional var display : String;
}
@:enum extern abstract ActionType(String) {
	var Send = "send";
    var AskFor = "askfor";
    var Turn = "turn";
}
@:enum extern abstract Filters(String) {
	var app_users = "app_users";
    var app_non_users = "app_non_users";
}
extern typedef ShareDialogParams = {
    > DialogParams,
    var method: String;
    var href : String;
    @:optional var hashtag : String;
    @:optional var quote : String;
    @:optional var mobile_iframe : Bool;
}
extern typedef FeedDialogParams = {
    > DialogParams,
    var method: String;
    var link : String;
}
extern typedef GameRequestDialogParams = {
    > DialogParams,
    var method: String;
    var message : String;
    @:optional var action_type: ActionType;
    @:optional var data : String;
    @:optional var exclude_ids : Array<String>;
    @:optional var filters: haxe.extern.EitherType<Array<Filters>, Array<{ name: String, user_ids: Array<String> }>>;//'app_users' | 'app_non_users' | Array<{ name: String, user_ids: Array<String> }>;
    @:optional var max_recipients : Float;
    @:optional var object_id : String;
    @:optional var suggestions : Array<String>;
    @:optional var title : String;
    @:optional var to:String;
}