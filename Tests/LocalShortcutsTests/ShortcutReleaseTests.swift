import AppKit
import Testing
@testable import LocalShortcuts

@Test @MainActor
func tabKeyUpDoesNotEndControlTabUntilControlIsReleased() throws {
    let name = LocalShortcuts.Name(
        "ControlTabReleaseTest",
        .init(modifier: [.control], keys: [.tab])
    )
    var downCount = 0
    var upCount = 0
    LocalShortcuts.Name.handlers[name] = { downCount += 1 }
    LocalShortcuts.Name.keyUpHandlers[name] = { upCount += 1 }
    defer {
        LocalShortcuts.Name.handlers[name] = nil
        LocalShortcuts.Name.keyUpHandlers[name] = nil
        LocalShortcuts.Name.shortcuts[name] = nil
    }

    func event(_ type: NSEvent.EventType, modifiers: NSEvent.ModifierFlags) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: type,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "\t",
            charactersIgnoringModifiers: "\t",
            isARepeat: false,
            keyCode: 48
        ))
    }

    _ = LocalShortcuts.Name.handle(event: try event(.keyDown, modifiers: .control))
    _ = LocalShortcuts.Name.handle(event: try event(.keyUp, modifiers: .control))
    _ = LocalShortcuts.Name.handle(event: try event(.keyDown, modifiers: .control))
    _ = LocalShortcuts.Name.handle(event: try event(.keyUp, modifiers: .control))
    #expect(downCount == 2)
    #expect(upCount == 0)

    _ = LocalShortcuts.Name.handle(event: try event(.flagsChanged, modifiers: []))
    _ = LocalShortcuts.Name.handle(event: try event(.flagsChanged, modifiers: []))
    #expect(upCount == 1)
}

@Test @MainActor
func unmodifiedShortcutEndsOnItsKeyUp() throws {
    let name = LocalShortcuts.Name(
        "PlainSReleaseTest",
        .init(modifier: [], keys: [.s])
    )
    var upCount = 0
    LocalShortcuts.Name.keyUpHandlers[name] = { upCount += 1 }
    defer {
        LocalShortcuts.Name.keyUpHandlers[name] = nil
        LocalShortcuts.Name.shortcuts[name] = nil
    }

    func event(_ type: NSEvent.EventType) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: type,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "s",
            charactersIgnoringModifiers: "s",
            isARepeat: false,
            keyCode: 1
        ))
    }

    _ = LocalShortcuts.Name.handle(event: try event(.keyDown))
    #expect(upCount == 0)
    _ = LocalShortcuts.Name.handle(event: try event(.keyUp))
    _ = LocalShortcuts.Name.handle(event: try event(.keyUp))
    #expect(upCount == 1)
}
