
var argscheck = require('cordova/argscheck'),
    exec = require('cordova/exec');

var fmbarcode_exports = {};

fmbarcode_exports.startCamera = function(success, error) {
	exec(success, error, "FMBarcode", "startCamera", []);
};

fmbarcode_exports.stopCamera = function(success, error) {
	exec(success, error, "FMBarcode", "stopCamera", []);
};

fmbarcode_exports.getJpegImage = function(success, error) {
	exec(success, error, "FMBarcode", "getJpegImage", []);
};

fmbarcode_exports.onCapture = function(success, error) {
	//TODO: Overwrite this methods for receiving the content
};

module.exports = fmbarcode_exports;

