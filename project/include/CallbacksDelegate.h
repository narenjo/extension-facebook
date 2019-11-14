#import <FBSDKShareKit/FBSDKGameRequestDialog.h>
#import <FBSDKShareKit/FBSDKSharing.h>

@class CallbacksDelegate;

@interface CallbacksDelegate : NSObject <
	FBSDKGameRequestDialogDelegate,
	FBSDKSharingDelegate
>

@end

