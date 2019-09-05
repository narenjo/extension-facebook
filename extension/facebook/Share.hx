package extension.facebook;

#if android
import extension.facebook.android.FacebookCFFI;
#elseif ios
import extension.facebook.ios.FacebookCFFI;
#elseif html5
import extension.facebook.html5.FacebookJS;
#end

class Share {

	public static function link(contentURL : String,
		quote : String = "",
		hashtag : String = "",
		contentDescription : String = "") {

		#if (android || ios)
		FacebookCFFI.shareLink(contentURL, quote, hashtag);
		#elseif html5
		var share:ShareDialogParams = {method: "share_open_graph", href: contentURL};
		if(hashtag != ""){
			share.hashtag = hashtag;
		}
		if(quote != ""){
			share.quote = quote;
		}
		FacebookJS.ui(share);
		#end

	}

	public static function setOnCompleteCallback(f : String->Void) {
		#if (android || iphone)
		FacebookCFFI.setOnShareComplete(f);
		#end
	}

	public static function setOnFailCallback(f : String->Void) {
		#if (android || iphone)
		FacebookCFFI.setOnShareFail(f);
		#end
	}

}
