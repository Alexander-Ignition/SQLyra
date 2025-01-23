#!/usr/bin/env swift

/*
 OVERVIEW: Convert Xcode Playground to markdown

 USAGE: cat Playgrounds/README.playground/Contents.swift | ./Scripts/markdown.swift
 */

enum TextBlock {
    case unknown, code, comment
}

var block = TextBlock.unknown

while let line = readLine() {
    switch block {
    case .unknown where line.isEmpty:
        break
    case .unknown where line.hasPrefix("/*"):
        block = .comment
    case .unknown:
        block = .code
        print("```swift")
        print(line)
    case .code where line.hasPrefix("/*"):
        block = .comment
        print("```")
    case .code:
        print(line)
    case .comment where line.hasSuffix("*/"):
        block = .unknown
    case .comment:
        print(line.drop(while: \.isWhitespace))
    }
}
