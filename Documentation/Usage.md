## Usage

### Making simple calls Alamofire-like

#### Just a call

```swift
import Nix

QuickCall(URL("string: https://httpbin.org/get")!)
```

This will simply call a given url. Simple as that. Call will be triggered automatically.

#### Receiving a response

QuickCall allows you to simply call an API and receive a response that will be automatically handled by serializers based on content type found in response header.

```swift

QuickCall(URL(string: "https://httpbin.org/get")!).success { (data) in

    print("JSON: \(data)")
    
    }.failure { (error) in
    
    print("Oops! Call has failed. Luckily, it's probably a NixError that contains a lot of information what exactly has gone wrong")
    
    switch error as? NixError ?? .unknown {
    
        case .httpError(let code):
            print("It's simply a HTTP error with code \(code)")
            break
        default:
            print("It's not HTTP error. I have to implement other cases handling")
            break
    }
    }.finally { (success) in

        print("This block is always called, doesn't matter if call has succeeded of failed. Just carries information if it did in success flag: \(success)")
}
```

Obviously, all network connectivity and parsing is done asynchronously, so blocks will never be invoked at once.

#### Different HTTP methods and parameters

It's easy to pass parameters and change HTTP methods using QuickCall

```swift
QuickCall(URL(string: "https://httpbin.org/post")!,
        method: .post,
        parameters: ["stringTest": "test", "numberTest": 2])
```

### Supporting a different content type

Out of the box, Nix supports JSON and XML content types, returning JSON dictionary structure or XMLParser for handling XML data. But you can easily add your own parser by creating a class inheriting from ResponseDecoding and registering it in NixManager.

```swift
open class PrivateDecoding: ResponseDecoding {

    override var contentType: String {
        get {
            return "application/privatedata"
        }
    }

    override open func decode(_ data: Data) throws -> Any? {
        return SomeParsingOfDataToMyObject(data)
    }
}

NixManager.shared.register(PrivateDecoding())
```

All calls, from now on, will have new content type handling.

### Implementing more sophisticated APIs

Real Nix magic starts when you want more powerfull API handling. Everything starts with ServerCall. A superclass that all your calls will be inheriting from overriding different parameters and methods to handle different scenarios.

#### Base URL

ServerCall Gives you a chance to ommit a necessity to put base URL directly in the code. It tries to read Application's Info.plist for parameter 'NixServerURL' which it will treat as a base URL of all calls. But you can do it manually by making your own base call class:

```swift

class MyServerCall: ServerCall {

    override var baseURLString: String {
        get {
            return "https://httpbin.org"
        }
    }
}
```

#### Parameters, paths, methods

Just like base URL, everything else is also structured and easy for you to change for each call. Let's take login use case as an example

```swift

class LoginCall: ServerCall {

    var username: String
    var password: String
    
    override var path: String {
        get { return "/login" }
    }
    
    override var method: HTTPMethod {
        get { return .post }
    }
    
    override var parameters: [String: Any]? {
        get { return ["username": username, "password": password] }
    }

    init(_ username: String, password: String) {
        self.username = username
        self.password = password
    }
}

LoginCall("someuser", password: "s3cr4t").success { (_) in
        print("Login succeeded")
    }.failure { (error) in
        print("Login failed")
}
```

#### Nested API calls

In some scenarios, there's a sequence of API calls you have to do, in order to deliver a single function. Nix supports those scenarios, thanks to the method onFinish() that you can ovverride in your api call class.

```swift
class NestedCall: TestCall {

    override var path: String {
        get { return "call2" }
    }
}

class InitialCall: TestCall {

    override var path: String {
        get { return "call1" }
    }

    override func onFinish(error: Error?) -> ServerCall? {
        if (error == nil) {
            userData = "testData"
            return NestedCall()
        }

        return nil
    }
}

InitialCall().success { (_) in
    print("That success is actually when NestedCall has finished running and parsing results")
}
```

... more examples to come...
