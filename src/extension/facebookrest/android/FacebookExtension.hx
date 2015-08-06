package extension.facebookrest.android;

import openfl.utils.JNI;

@:build(ShortCuts.mirrors())
class FacebookExtension {

	@JNI("org.haxe.extension.facebook", "init")
	public static function init() {}

	@JNI("org.haxe.extension.facebook", "appInvite")
	public static function appInvite(appLinkUrl : String, previewImageUrl : String) {}

	public static function setCallBackObject(c : FacebookCallbacks) {
		var fn = JNI.createStaticMethod(
			"org.haxe.extension.facebook.FacebookExtension",
			"setCallBackObject",
			"(Lorg/haxe/lime/HaxeObject;)V"
		);
		JNI.callStatic(fn, [c]);
	}

}
