# KoalaTeaAutoLayout

[![CI Status](https://img.shields.io/travis/themisterholliday/KoalaTeaAutoLayout.svg?style=flat)](https://travis-ci.org/themisterholliday/KoalaTeaAutoLayout)
[![Version](https://img.shields.io/cocoapods/v/KoalaTeaAutoLayout.svg?style=flat)](https://cocoapods.org/pods/KoalaTeaAutoLayout)
[![License](https://img.shields.io/cocoapods/l/KoalaTeaAutoLayout.svg?style=flat)](https://cocoapods.org/pods/KoalaTeaAutoLayout)
[![Platform](https://img.shields.io/cocoapods/p/KoalaTeaAutoLayout.svg?style=flat)](https://cocoapods.org/pods/KoalaTeaAutoLayout)

A custom AutoLayout DSL wrapper building on top of the amazing work of [John Sundell](https://twitter.com/johnsundell) in the blog post [Building DSLs in Swift](https://www.swiftbysundell.com/posts/building-dsls-in-swift).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

```
iOS 11.0+
```

## Installation

KoalaTeaAutoLayout is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KoalaTeaAutoLayout'
```

## Usage

Always have to import first

```swift
import KoalaTeaAutoLayout
```

And then you can use the library like so:

```swift
let layoutView = UIView()
self.view.addSubview(layoutView)
layoutView.backgroundColor = .red
layoutView.layout {
    $0.top == self.view.safeAreaLayoutGuide.topAnchor
    $0.leading == self.view.leadingAnchor + 20
    $0.trailing == self.view.trailingAnchor - 20
    $0.height.equal(to: self.view.heightAnchor, multiplier: 0.1)
}
```

or you could have the constraints returned and activate/deactivate them at will:

```swift
var constraints1: [NSLayoutConstraint] = []
var constraints2: [NSLayoutConstraint] = []

self.view.addSubview(layoutView)
layoutView.backgroundColor = .blue
constraints1 = layoutView.returnedLayout {
    return [
        $0.centerXAnchor == self.view.centerXAnchor,
        $0.bottom == self.view.safeAreaLayoutGuide.bottomAnchor,
        $0.height == 80,
        $0.width == $0.height + 100,
    ]
}

constraints2 = layoutView.returnedLayout {
    return [
        $0.top == layoutView2.bottomAnchor,
        $0.centerXAnchor == self.view.centerXAnchor,
        $0.height == 80,
        $0.width == $0.height + 100,
    ]
}
constraints2.deactivateAll()

animate()

func animate() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.constraints1.deactivateAll()
        self.constraints2.activateAll()

        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.constraints2.deactivateAll()
                self.constraints1.activateAll()

                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.animate()
                })
            }
        })
    }
}
```

There are also some convenience functions setup for common use cases:

```swift
let edgesToSuperview = UIView()
edgesToSuperview.constrainEdgesToSuperview()

let centerToSuperview = UIView()
centerToSuperview.constrainCenterToSuperview()

let edgesToAnotherView = UIView()
edgesToAnotherView.constrainEdges(to: centerToSuperview)
```

## Contributing

Open an issue.

Open a PR.

or shoot me an email and I'll get back to you.

## Author

Craig Holliday

email: hello@craigholliday.net

twitter: https://twitter.com/TheMrHolliday

## License

KoalaTeaAutoLayout is available under the MIT license. See the LICENSE file for more info.
