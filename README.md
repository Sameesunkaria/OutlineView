# OutlineView for SwiftUI on macOS

`OutlineView` is a SwiftUI view for macOS, which allows you to display hierarchical visual layouts (like directories and files) that can be expanded and collapsed. 
It provides a convenient wrapper around AppKit's `NSOutlineView`, similar to SwiftUI's `OutlineGroup`. `OutlineView` differs from the native `OutlineGroup` as it provides it's own scroll view and doesn't have to be embedded in a `List`.

<p align="center">
  <img width="606" alt="Screenshot" src="Example/Screenshot.png">
</p>

## Installation

You can install the `OutlineView` package using SwiftPM.

```
https://github.com/Sameesunkaria/OutlineView.git
```

## Usage

The API of the `OutlineView` is similar to the native `OutlineGroup` or of a `List` with children.

In the following example, a tree structure of `FileItem` data offers a simplified view of a file system. Passing a sequence of root elements of this tree and the key path of its children allows you to quickly create a visual representation of the file system.

A macOS app demonstrating this example can be found in the `Example` directory.

```swift
struct FileItem: Hashable, Identifiable, CustomStringConvertible {
  // Each item in the hierarchy should be uniquely identified.
  var id = UUID()
  
  var name: String
  var children: [FileItem]? = nil
  var description: String {
    switch children {
    case nil:
      return "📄 \(name)"
    case .some(let children):
      return children.isEmpty ? "📂 \(name)" : "📁 \(name)"
    }
  }
}

let data = [
  FileItem(
    name: "user1234",
    children: [
      FileItem(
        name: "Photos",
        children: [
          FileItem(name: "photo001.jpg"),
          FileItem(name: "photo002.jpg")]),
      FileItem(
        name: "Movies",
        children: [FileItem(name: "movie001.mp4")]),
      FileItem(name: "Documents", children: [])]),
  FileItem(
    name: "newuser",
    children: [FileItem(name: "Documents", children: [])])
]

@State var selection: FileItem?

OutlineView(data, children: \.children, selection: $selection) { item in
  NSTextField(string: item.description)
}
```

### Customization

#### Style
You can customize the look of the `OutlineView` by providing a preferred style (`NSOutlineView.Style`) in the `outlineViewStyle` method. The default value is `.automatic`.

```swift
OutlineView(data, children: \.children, selection: $selection) { item in
  NSTextField(string: item.description)
}
.outlineViewStyle(.sourceList)
```

#### Indentation

You can customize the indentation width for the `OutlineView`. Each child will be indented by this width, from the parent's leading inset. The default value is `13.0`.

```swift
OutlineView(data, children: \.children, selection: $selection) { item in
  NSTextField(string: item.description)
}
.outlineViewIndentation(20)
```

## Why use `OutlineView` instead of the native `OutlineGroup`?

`OutlineView` is meant to serve as a stopgap solution to a few of the quirks of an `OutlineGroup` on macOS.

- The current implementation of updates on the `OutlineGroup` is miscalculated, which leads to incorrect cell updates on the UI and crashes due to accessing invalid indices on the internal model. This bug makes the `OutlineGroup` unusable on macOS unless you are working with static content.
- It is easier to expose more of the built-in features of an `NSOutlineView` as we have full control over the code, which enables bringing over additional features in the future like support for grid lines and multiple columns.
- Currently, `OutlineView` has the same minimum deployment target as `OutlineGroup` (macOS 11). However, it is easy to lower the deployment target if the need arises.
- `OutlineView` supports row animations for updates by default.

## Caveats

`OutlineView` is implemented using the public API for SwiftUI, leading to some limitations that are hard to workaround.

- The content of the cells has to be represented as an `NSView`. This is required as `NSOutlineView` has internal methods for automatically changing the selected cell's text color. A SwiftUI `Text` is not accessible from AppKit, and therefore, any SwiftUI `Text` views will not be able to adopt the system behavior for the highlighted cell's text color. Providing an `NSView` with `NSTextField`s for displaying text allows us to work around that limitation.
- Automatic height `NSOutlineView`s still seems to require an initial cell height to be provided. This in itself is not a problem, but the default `fittingSize` of an `NSView` with the correct constraints around a multiline `NSTextField` is miscalculated. The `NSTextField`'s width does not seem to be bounded when the fitting size is calculated (even if a correct max-width constraint was provided to the `NSView`). So, if you have a variable height `NSView`, you have to make sure that the `fittingSize` is computed appropriately.
