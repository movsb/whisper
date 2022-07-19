#  <#Title#>

## 06.30

* 在 init 里面无法更新 @State 变量：<https://stackoverflow.com/a/61550011/3628322>


## 单元测试

* [Getting Started with Swift Unit Testing in Xcode – Swift Dev Journal](https://www.swiftdevjournal.com/getting-started-with-swift-unit-testing-in-xcode/)

## 07.01

* 文件共享：[swift - How do I share files using share sheet in iOS? - Stack Overflow](https://stackoverflow.com/questions/35851118/how-do-i-share-files-using-share-sheet-in-ios)
* 时间格式参考：[NSDateFormatter.com - Live Date Formatting Playground for Swift](https://nsdateformatter.com/#reference)
* 时间格式化：[How to Convert a Date to a String In Swift](https://cocoacasts.com/swift-fundamentals-how-to-convert-a-date-to-a-string-in-swift)

隐藏键盘：

* [ios - How to hide keyboard when using SwiftUI? - Stack Overflow](https://stackoverflow.com/a/56496669/3628322)

FaceID：

* [Using Touch ID and Face ID with SwiftUI - a free Hacking with iOS: SwiftUI Edition tutorial](https://www.hackingwithswift.com/books/ios-swiftui/using-touch-id-and-face-id-with-swiftui)


## 07.03

Share Extension：

* [ios - How to add my app to the share sheet action - Stack Overflow](https://stackoverflow.com/a/46882011/3628322)
* [How to create a Share Extension in Swift - MiddlewareExpert](https://middlewareworld.org/2021/05/07/how-to-create-a-share-extension-in-swift/)
  * 提取分享对象类型
  * 播放视频
* [Sharing data between iOS apps and app extensions • The Atomic Birdhouse](https://www.atomicbird.com/blog/sharing-with-app-extensions/)
  * [atomicbird/iOS-Extension-Demo: Demonstration of creating iOS "today" and "share" extensions](https://github.com/atomicbird/iOS-Extension-Demo)
* [Blog - Building an iOS share extension programmatically in Swift · Hello Code.](https://blog.hellocode.co/post/share-extension/)
  * 讲了 @objc 的使用。
* [Implementing share extensions in Swift | by Oluwadamisi Pikuda | Medium](https://medium.com/@damisipikuda/how-to-receive-a-shared-content-in-an-ios-application-4d5964229701)
* [iOS Share extension — Swift 5.1. Share contents into your app in a few… | by Fabio Pelizzola | Mac O’Clock | Medium](https://medium.com/macoclock/ios-share-extension-swift-5-1-1606263746b)
* [Airlist - News, Updates, and Releases](https://airlist.app/blog/swiftui-share-extension)
* [(126) UIHostingController in SwiftUI 2020 (Use in UIViewController) - How To Bridge UIKit with SwiftUI. - YouTube](https://www.youtube.com/watch?v=z_9EOGDw5uk)
  * 如何在 Share Extension 里面使用 SwiftUI
* [Sharing information between iOS app and an extension](https://rderik.com/blog/sharing-information-between-ios-app-and-an-extension/)
  * 比较全面的文档

语言：

* [What Is The Difference Between Try, Try?, And Try!](https://cocoacasts.com/what-is-the-difference-between-try-try-and-try)
  * 很清晰的文档讲解了几种 `try` 的区别。

## 07.04

* [How to use @EnvironmentObject to share data between views - a free SwiftUI by Example tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-environmentobject-to-share-data-between-views)
  * 环境变量的使用，可以大量减少参数在 Views 之间的传递。

## 07.05

SwiftUI：

* [How could I initialize the @State variable in the init function in SwiftUI? - Stack Overflow](https://stackoverflow.com/a/60028709/3628322)
  * 在 init 中初始化 @State 变量
* [How to let users delete rows from a list - a free SwiftUI by Example tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-let-users-delete-rows-from-a-list)
  * 实现滑动删除


状态管理：

* [SwiftUI: @State vs @StateObject vs @ObservedObject vs @EnvironmentObject | by Sam Wright | Level Up Coding](https://levelup.gitconnected.com/state-vs-stateobject-vs-observedobject-vs-environmentobject-in-swiftui-81e2913d63f9)
  * 比较详细的说明了几种状态管理的区别，特别是后面的总结比较好。

## 07.06

SwiftUI

* [How to show multiple alerts on the same view in SwiftUI | Sarunw](https://sarunw.com/posts/how-to-show-multiple-alerts-on-the-same-view-in-swiftui/)
  * 多个 alert 无法工作的问题

错误处理：

* [How to throw errors using strings - free Swift 5.4 example code and tips](https://www.hackingwithswift.com/example-code/language/how-to-throw-errors-using-strings)
  * 抛出字符串型错误。


定时器的使用：

* [Triggering events repeatedly using a timer - a free Hacking with iOS: SwiftUI Edition tutorial](https://www.hackingwithswift.com/books/ios-swiftui/triggering-events-repeatedly-using-a-timer)


## 07.07

照片选择、拍照、拍视频：

* [ImagePicker - SwiftUI Advanced Handbook - Design+Code](https://designcode.io/swiftui-advanced-handbook-imagepicker)
* [ios - How to select Multiple images from UIImagePickerController - Stack Overflow](https://stackoverflow.com/questions/20756899/how-to-select-multiple-images-from-uiimagepickercontroller)
  * 自带的图片选择居然不支持多选，其它的又有权限问题，干！
  * [ios - Select Multiple Images (UIImagePickerController or Photos.app Share UI) - Stack Overflow](https://stackoverflow.com/a/64706937/3628322)

## 07.08

密钥学：

* [Introducing CryptoKit | raywenderlich.com](https://www.raywenderlich.com/10846296-introducing-cryptokit)
* [swift - CryptoKit encrypt file too big for memory - Stack Overflow](https://stackoverflow.com/q/60607679/3628322)
  * AES.GCM 是流加密模式，为什么不支持流数据输入？为了并行？

## 07.09

手势操作：

* [Long Press Gesture - SwiftUI Handbook - Design+Code](https://designcode.io/swiftui-handbook-long-press)

## 07.10

上架准备：

* [App Icon Generator](https://appicon.co)

## 07.11

分享扩展：

* [ios - Share Extension to open containing app - Stack Overflow](https://stackoverflow.com/a/44499222/3628322)
  * 如何在 Share Extension 内打开主应用。
* [application\(\_:open:options:\) | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623112-application)
* [How to add an AppDelegate to a SwiftUI app - a free SwiftUI by Example tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-an-appdelegate-to-a-swiftui-app)

生命周期变化通知：

* [How to be notified when your SwiftUI app moves to the background - a free Hacking with iOS: SwiftUI Edition tutorial](https://www.hackingwithswift.com/books/ios-swiftui/how-to-be-notified-when-your-swiftui-app-moves-to-the-background)

## 07.12

在分享扩展的 viewDidLoad 里面关闭弹窗：<https://stackoverflow.com/a/64124289/3628322>
允许 Text 的文本选择：<https://stackoverflow.com/a/59667107/3628322>

## 07.13

关于状态，仍然不懂：

* [@StateObject vs. @ObservedObject: The differences explained - SwiftLee](https://www.avanderlee.com/swiftui/stateobject-observedobject-differences/)
* [Why @State only works with structs - a free Hacking with iOS: SwiftUI Edition tutorial](https://www.hackingwithswift.com/books/ios-swiftui/why-state-only-works-with-structs)
* [Managing Model Data in Your App | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)


## 07.17

分享页不能在已弹出页继续弹出的问题解决： [I'm trying to present a share sheet but it doesn't work when done from inside a sheet. : SwiftUI](https://www.reddit.com/r/SwiftUI/comments/qfs8x3/im_trying_to_present_a_share_sheet_but_it_doesnt/?utm_source=share&utm_medium=web2x&context=3)

文件类型注册：

* [Registering the File Types Your App Supports](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/DocumentInteraction_TopicsForIOS/Articles/RegisteringtheFileTypesYourAppSupports.html#//apple_ref/doc/uid/TP40010411-SW1)
* [Technical Q&A QA1587: How do I get my application to show up in the Open in... menu.](https://developer.apple.com/library/archive/qa/qa1587/_index.html)


## 07.18

### 审核

各设备尺寸：
- <https://www.ios-resolution.com/>
- <https://help.apple.com/app-store-connect/#/devd274dd925>

显示开始结束时间：`for commit in f08f261 f417e38; do git log -1 --format=reference $commit; done`

## 07.19

状态管理：

* [ios - Pass state/binding to UIViewRepresentable - Stack Overflow](https://stackoverflow.com/a/61969628/3628322)
  - 如果在自定义 View 中实现状态变量的绑定。
