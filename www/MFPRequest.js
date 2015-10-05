var exec = require("cordova/exec");

var MFPRequest = function (url, method, timeout) {    
    this.TAG = "javascript-MFPRequest ";

    this._headers = {};
    this._queryParameters = {};
    this._url = url;
    this._method = method;
    this._timeout = timeout || 30000;
};

MFPRequest.GET = "GET";
MFPRequest.PUT = "PUT";
MFPRequest.POST = "POST";
MFPRequest.DELETE = "DELETE";
MFPRequest.TRACE = "TRACE";
MFPRequest.HEAD = "HEAD";
MFPRequest.OPTIONS = "OPTIONS";

MFPRequest.prototype = function () {

    /**
     * Set the headers for the request object
     * @param jsonObj
     */
    var setHeaders = function (jsonObj) {
        //performant Deep Clone the json object
        this._headers = JSON.parse(JSON.stringify(jsonObj));
    };

    /**
     * Return the headers object for the request object
     * @param
     * @returns {null, string}
     */
    var getHeaders = function () {
        return this._headers;
    };

    /**
     * Return the url for this request
     * @returns {string}
     */
    var getUrl = function () {
        return this._url;
    };

    /**
     * Return the HTTP method for this request
     * @returns {string}
     */
    var getMethod = function () {
        return this._method;
    };

    /**
     * Return the timeout (in ms) for this request
     * @returns {number}
     */
    var getTimeout = function () {
        return this._timeout;
    };

    /**
     * Return the queryParameters object for this request
     * @returns JSON
     */
    var getQueryParameters = function () {
        return this._queryParameters;
    };

    /**
     * Set the Query Parameters for the request object
     * @param jsonObj
     */
    var setQueryParameters = function (jsonObj) {
        //performant Deep Clone the json object
        this._queryParameters = JSON.parse(JSON.stringify(jsonObj));
    };

    /**
     * Send this resource request asynchronously.
     * @param body (Optional) The body: Either a string or an object
     * @param success The success callback that was supplied
     * @param failure The failure callback that was supplied
     */
    var send = function () {
        var buildRequest = buildJSONRequest.bind(this);

        if(arguments.length == 2) {
            // Empty Body
            console.log(this.TAG + " send with empty body");
            var cbSuccess = callbackWrap.bind(this, arguments[0]);
            var cbFailure = callbackWrap.bind(this, arguments[1]);

            cordova.exec(cbSuccess, cbFailure, "MFPRequest", "send", [buildRequest()]);
        } else if(arguments.length >= 3) {
            // Non-empty Body 
            if(typeof arguments[0] == "string" || typeof arguments[0] == "object") {
                console.log(this.TAG + " send with string or object for the body");
                var cbSuccess = callbackWrap.bind(this, arguments[1]);
                var cbFailure = callbackWrap.bind(this, arguments[2]);
                cordova.exec(cbSuccess, cbFailure, "MFPRequest", "send", [buildRequest(arguments[0])]);
            }
        }
    };

    /**
     *
     * @param callback The Success or Failure callback
     * @param jsonResponse string : The string-form JSON response coming from the Native SDK.
     */
    var callbackWrap = function (callback, jsonResponse) {
        var response = JSON.parse(jsonResponse);
        callback(response);
    };

    var buildJSONRequest = function (body) {
        var request = {};

        request.url = this.getUrl();
        request.method = this.getMethod();
        request.headers = this.getHeaders();
        request.timeout = this.getTimeout();
        request.queryParameters = this.getQueryParameters();
        request.body = "";

        if (typeof body === "string") {
            request.body = body;
        }
        else if (typeof body === "object") {
            request.body = JSON.stringify(body);
            if (!("Content-Type" in this._headers)) {
                request.headers["Content-Type"] = "application/json";
            }
        }
        //TODO update when Logger is complete
        console.log(this.TAG + " The request is: " + JSON.stringify(request));
        return request;
    };

    return {
        setHeaders: setHeaders,
        getHeaders: getHeaders,
        getUrl: getUrl,
        getMethod: getMethod,
        getTimeout: getTimeout,
        setQueryParameters: setQueryParameters,
        getQueryParameters: getQueryParameters,
        send: send
    }
}();

module.exports = MFPRequest;