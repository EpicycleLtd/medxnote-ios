#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.delay(10);

captureLocalizedScreenshot("0-InboxScreen");

// Open Masha's Conversation

target.frontMostApp().mainWindow().tableViews()[0].cells()[2].tap();

captureLocalizedScreenshot("1-MahshaDiscussionView");

// Open Fingerprint View
target.frontMostApp().navigationBar().tapWithOptions({tapOffset:{x:0.43, y:0.49}, duration:1.6});
captureLocalizedScreenshot("10-FingerprintView")
target.frontMostApp().mainWindow().buttons()["×"].tap();

// Back to Conversations
target.frontMostApp().navigationBar().leftButton().tap();

// Open New Conversation
target.frontMostApp().navigationBar().rightButton().tap();

captureLocalizedScreenshot("2-NewDiscussionView");

// New Group

target.frontMostApp().navigationBar().rightButton().tap();

target.frontMostApp().mainWindow().textFields()[0].textFields()[0].tap();
target.frontMostApp().keyboard().typeString("Nihilist History Book Club");
target.frontMostApp().keyboard().typeString("\n");

target.frontMostApp().mainWindow().tableViews()[0].tapWithOptions({tapOffset:{x:0.27, y:0.32}});
target.frontMostApp().mainWindow().tableViews()[0].tapWithOptions({tapOffset:{x:0.14, y:0.13}});

captureLocalizedScreenshot("3-NewGroupView");

target.frontMostApp().mainWindow().textFields()[0].textFields()[0].tap();
target.frontMostApp().keyboard().typeString("\n");

target.frontMostApp().navigationBar().leftButton().tap();
target.frontMostApp().navigationBar().leftButton().tap();

// Opening Archive

target.frontMostApp().mainWindow().buttons()[1].tap();
captureLocalizedScreenshot("4-EmptyArchiveScreen")

// Opening Settings
target.frontMostApp().navigationBar().leftButton().tap();
captureLocalizedScreenshot("5-SettingsScreen");


