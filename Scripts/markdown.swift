#!/usr/bin/env swift

// Convert Xcode Playground to markdown
// Usage: cat Playgrounds/Example.playground/Contents.swift | ./Scripts/markdown.swift

enum TextBlock {
    case unknown, code, comment
}

var block = TextBlock.unknown

while let line = readLine() {
    if line.hasPrefix("/*") {
        if block == .code {
            print("```")
        }
        block = .comment
    } else if line.hasSuffix("*/") {
        print("```swift")
        block = .code
    } else if block == .comment {
        print(line.drop(while: \.isWhitespace))
    } else {
        print(line)
    }
}
if block == .code {
    print("```")
}
