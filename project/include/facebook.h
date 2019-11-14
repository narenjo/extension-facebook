#include <string>
#include <vector>

#ifndef _FACEBOOK_H_
#define _FACEBOOK_H_

namespace extension_facebook {

	void pre_init();
	void init();
	void logOut();

	void logInWithPublishPermissions(std::vector<std::string> &permissions);
	__attribute((deprecated("Use logInWithPermissions(std::vector<std::string> &permissions)")));
	void logInWithReadPermissions(std::vector<std::string> &permissions);
	__attribute((deprecated("Use logInWithPermissions(std::vector<std::string> &permissions)")));
	void logInWithPermissions(std::vector<std::string> &permissions);

	void shareLink(
		std::string contentURL,
		std::string contentTitle,
		std::string imageURL,
		std::string contentDescription
	);

	void graphRequest(
		std::string graphPath,
		std::vector<std::string> &parameters,
		std::string methodStr
	);

	void appRequest(
		std::string message,
		std::string title,
		std::vector<std::string> &recipients,
		std::string objectId,
		int actionType,
		std::string data
	);

	void onTokenChange(const char *token);

	void onLoginSuccessCallback();
	void onLoginCancelCallback();
	void onLoginErrorCallback(const char *error);

	void onGraphRequestComplete(const char *json);
	void onGraphRequestFail(const char *error);

	void onAppRequestComplete(const char *json);
	void onAppRequestFail(const char *error);

	void onShareComplete(const char *json);
	void onShareFail(const char *error);

}

#endif
