var fbLoaded = false;
var fbAppId = '::SET_FACEBOOK_APP_ID::';
window.fbAsyncInit = function() {
    FB.init({
        appId            : fbAppId,
        autoLogAppEvents : true,
        xfbml            : true,
        version          : 'v4.0'
    });
    fbLoaded = true;
};