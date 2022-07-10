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
