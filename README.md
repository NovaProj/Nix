#  NIX - Network Interface eXtension

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Nix.svg)](https://img.shields.io/cocoapods/v/Nix.svg)
[![Platform](https://img.shields.io/cocoapods/p/Nix.svg?style=flat)](https://github.com/NovaProj/Nix)

Nix is an HTTP networking library written in Swift. On top of - already superb Apple solution with URLSession, Nix adds structure to your API connectivity, allowing you to keep your connectivity part of the application clean and easy to change/extend.

- [Features](#features)
- [Requirements](#requirements)
- [Communication](#communication)
- [Installation](#installation)
- [FAQ](#faq)
- [TODOs](#todo)
- [License](#license)

## Features

- [x] Chainable Request / Response Methods
- [x] URL / JSON
- [x] HTTP Response Validation

## Requirements

- iOS 10.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 8.3+
- Swift 3.1+

## Communication
- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/nixswift). (Tag 'nixswift')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/nixswift).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1+ is required to build Nix

To integrate Nix into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Nix'
end
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate Nix into your project manually.

#### Embedded Framework

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add Nix as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/NovaProj/Nix.git
```

- Open the new `Nix` folder, and drag the `Nix.xcodeproj` into the Project Navigator of your application's Xcode project.

> It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `Nix.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `Nix.xcodeproj` folders each with two different versions of the `Nix.framework` nested inside a `Products` folder.

> It does not matter which `Products` folder you choose from, but it does matter whether you choose the top or bottom `Nix.framework`.

- Select the top `Nix.framework` for iOS and the bottom one for OS X.


- And that's it!

> The `Nix.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

## FAQ

### Why Nix?

Why the name? Because Apple already has a great tool for any network connectivity. It just needed a bit of a final touch so all the code you make for your calls are structured, understandable and in one place. It's very basic and will get more functions in time (more about it in [TODO](#todo) section). But it's main aim is to be simple and structured.

### What's wrong with other libraries out there?

There's nothing wrong with them. I myself was using [Alamofire](https://github.com/Alamofire/Alamofire) most of my Swift life. Fact is, that Alamofire was a product of necessity when URLSession wasn't as pretty as it is now. And with time, I have found out that I don't really get how Alamofire does things. I hate not to know.

At the end of the day, most of the projects I was doing lacked the structure for internet calls. As much as most libraries gives you functions, they lack most important element that Apple brings with their Foundation and UIKit - structure. And that's the reason for Nix.

## TODO

There's a lot of things that still has to be implemented in Nix. Most important ones are as follows:

- [ ]  Download File using Request or Resume Data
- [ ] Upload File / Data / Stream / MultipartFormData
- [ ] Upload and Download Progress Closures with Progress
- [ ] Authentication with URLCredential
- [ ] Network Reachability
- [ ] Documentation
- [ ] More tests

## License

Nix is released under the MIT license. [See LICENSE](https://github.com/NovaProj/Nix/blob/master/LICENSE) for details.

