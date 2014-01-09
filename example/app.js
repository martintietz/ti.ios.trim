var trimmer = require('ti.ios.trim');

var textFieldOptions = {
	width: 300,
	height: 35,
	borderStyle: Ti.UI.INPUT_BORDERSTYLE_ROUNDED,
	keyboardType: Ti.UI.KEYBOARD_NUMBER_PAD
};

var win = Ti.UI.createWindow({ backgroundColor: 'black', layout: 'vertical', top: 20 });
var textFieldStart = Ti.UI.createTextField(textFieldOptions);
win.add(textFieldStart);
var textFieldStop = Ti.UI.createTextField(textFieldOptions);
win.add(textFieldStop);
var button = Ti.UI.createButton({ title: 'Trim Video' });
button.addEventListener('click', trimVideo);
win.add(button);
win.open();

var videoPlayer = null;

function trimVideo() {
	textFieldStart.blur();
	textFieldStop.blur();

	button.enabled = false;

	var inputFile = Ti.Filesystem.getFile('big_buck_bunny.m4v');

	trimmer.trimVideo({
		input: inputFile.resolve(),
		quality: 1,
		startTime: textFieldStart.value,
		endTime: textFieldStop.value,
		success: function(e) {
			playVideo(e.videoURL);
			button.enabled = true;
		},
		error: function(e) {
			alert('ERROR: '+ JSON.stringify(e));
			button.enabled = true;
		}
	});
}

function playVideo(videoURL) {
	releaseVideoPlayer();
	videoPlayer = Titanium.Media.createVideoPlayer({
		autoplay: true,
		height : 300,
		width : 300,
		mediaControlStyle : Titanium.Media.VIDEO_CONTROL_DEFAULT,
		scalingMode : Titanium.Media.VIDEO_SCALING_ASPECT_FIT,
		media: videoURL
	});
	win.add(videoPlayer);
}

function releaseVideoPlayer() {
	if (!videoPlayer) {
		return;
	}

	videoPlayer.stop();
	videoPlayer.release();
	win.remove(videoPlayer);
	videoPlayer = null;
}