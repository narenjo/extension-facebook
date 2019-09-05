var fbLoaded = false;
window.fbAsyncInit = function() {
    FB.init({
        appId            : '::SET_FACEBOOK_APP_ID::',
        autoLogAppEvents : true,
        xfbml            : true,
        version          : 'v4.0'
    });
    fbLoaded = true;
};