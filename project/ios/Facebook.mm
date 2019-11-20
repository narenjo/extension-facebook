#import <CallbacksDelegate.h>
#import <FacebookObserver.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKGameRequestContent.h>
#import <FBSDKShareKit/FBSDKGameRequestDialog.h>
#import <FBSDKShareKit/FBSDKShareDialog.h>
#import <FBSDKShareKit/FBSDKShareLinkContent.h>

#import <Facebook.h>

namespace extension_facebook {

	CallbacksDelegate *callbacks;
	FacebookObserver *obs;
	FBSDKLoginManager *login;
	UIViewController *root;

	void pre_init() {
		login = [[FBSDKLoginManager alloc] init];
		obs = [[FacebookObserver alloc] init];
		[[NSNotificationCenter defaultCenter]
			addObserver:obs
			selector:@selector(applicationDidFinishLaunchingNotification:)
			name:@"UIApplicationDidFinishLaunchingNotification"
			object:nil
		];
	}

	void init() {
		root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
		callbacks = [[CallbacksDelegate alloc] init];
		
		[[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication]
									didFinishLaunchingWithOptions:[[NSMutableDictionary alloc] init]];
		
		[obs observeTokenChange:nil];

		[[NSNotificationCenter defaultCenter]
			addObserver:obs
			selector:@selector(observeTokenChange:)
			name:FBSDKAccessTokenDidChangeNotification
			object:nil
		];

	}

	void logOut() {
		[login logOut];
	}
	
	void logInWithPublishPermissions(std::vector<std::string> &permissions) {
		logInWithPermissions(permissions);
	}

	void logInWithReadPermissions(std::vector<std::string> &permissions) {
		logInWithPermissions(permissions);
	}

	void logInWithPermissions(std::vector<std::string> &permissions) {
		NSMutableArray *nsPermissions = [[NSMutableArray alloc] init];
		for (auto p : permissions) {
			[nsPermissions addObject:[NSString stringWithUTF8String:p.c_str()]];
		}
		[login logInWithPermissions:nsPermissions fromViewController:root handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
			if (error) {
				onLoginErrorCallback([error.localizedDescription UTF8String]);
			} else if (result.isCancelled) {
				onLoginCancelCallback();
			} else {
				onLoginSuccessCallback();
			}
		}];
	}

	void shareLink(
		std::string contentURL,
		std::string quote,
		std::string hashtag) {

		FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
		content.contentURL = [NSURL URLWithString:[NSString stringWithUTF8String:contentURL.c_str()]];
		if (quote!="") {
			content.quote = [NSString stringWithUTF8String:quote.c_str()];
		}
		if (hashtag!="") {
			content.hashtag = [FBSDKHashtag hashtagWithString:[NSString stringWithUTF8String:hashtag.c_str()]];
		}

		int osVersion = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
		FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
		dialog.fromViewController = root;
		dialog.shareContent = content;
		dialog.delegate = callbacks;
		if (osVersion>=9) {
			dialog.mode = FBSDKShareDialogModeFeedWeb;
		}
		[dialog show];

	}

	void graphRequest(
		std::string graphPath,
		std::vector<std::string> &parameters,
		std::string methodStr) {

		NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
		for (auto p : parameters) {
			[params setValue:[[[NSString stringWithUTF8String:p.c_str()] componentsSeparatedByString:@"||"] objectAtIndex:0] forKey:[[[NSString stringWithUTF8String:p.c_str()] componentsSeparatedByString:@"||"] objectAtIndex:1]];
		}

		FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
			initWithGraphPath:[NSString stringWithUTF8String:graphPath.c_str()]
				parameters:params
				HTTPMethod:[NSString stringWithUTF8String:methodStr.c_str()]];
		[request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
			if (error) {
				//NSLog(@"%s",[error.localizedDescription UTF8String]);
				onGraphRequestFail([error.localizedDescription UTF8String]);
			} else {
				NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result
											options:0
											error:&error];
				onGraphRequestComplete([[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] UTF8String]);
			}
		}];
	}

	void appRequest(
		std::string message,
		std::string title,
		std::vector<std::string> &recipients,
		std::string objectId,
		int actionType,
		int filters,
		std::string data) {

		FBSDKGameRequestContent *gameRequestContent = [[FBSDKGameRequestContent alloc] init];
		gameRequestContent.message = [NSString stringWithUTF8String:message.c_str()];
		gameRequestContent.title = [NSString stringWithUTF8String:title.c_str()];

		NSMutableArray *nsRecipients = [[NSMutableArray alloc] init];
		for (auto p : recipients) {
			[nsRecipients addObject:[NSString stringWithUTF8String:p.c_str()]];
		}
		gameRequestContent.recipients = nsRecipients;

		if (objectId!="") {
			gameRequestContent.objectID = [NSString stringWithUTF8String:objectId.c_str()];
		}

		switch (actionType) {
			case 1:
			gameRequestContent.actionType = FBSDKGameRequestActionTypeSend;
			break;
			case 2:
			gameRequestContent.actionType = FBSDKGameRequestActionTypeAskFor;
			break;
			case 3:
			gameRequestContent.actionType = FBSDKGameRequestActionTypeTurn;
			break;
			default:
			gameRequestContent.actionType = FBSDKGameRequestActionTypeSend;
			break;
		}

		switch (filters) {
			case 1:
			gameRequestContent.filters = FBSDKGameRequestFilterAppUsers;
			break;
			case 2:
			gameRequestContent.filters = FBSDKGameRequestFilterAppNonUsers;
			break;

		if (data!="") {
			gameRequestContent.data = [NSString stringWithUTF8String:data.c_str()];
		}
		[FBSDKGameRequestDialog showWithContent:gameRequestContent delegate:callbacks];

	}

}
