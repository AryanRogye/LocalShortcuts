import AppKit
import Testing
@testable import LocalShortcuts

@Test @MainActor
func nonRepeatingShortcutRunsOncePerKeyPress() throws {
    let name = LocalShortcuts.Name(
        "NonRepeatingShortcutTest",
        .init(modifier: [.command], keys: [.s])
    )
    var invocationCount = 0
    LocalShortcuts.Name.handlers[name] = { invocationCount += 1 }
    LocalShortcuts.Name.allowsRepeat[name] = false
    LocalShortcuts.Name.consumesEvents[name] = false
    defer {
        LocalShortcuts.Name.handlers[name] = nil
        LocalShortcuts.Name.allowsRepeat[name] = nil
        LocalShortcuts.Name.consumesEvents[name] = nil
        LocalShortcuts.Name.shortcuts[name] = nil
    }

    func event(
        _ type: NSEvent.EventType,
        repeat isRepeat: Bool = false,
        timestamp: TimeInterval = 0,
        modifiers: NSEvent.ModifierFlags = .command
    ) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: type,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: timestamp,
            windowNumber: 0,
            context: nil,
            characters: "s",
            charactersIgnoringModifiers: "s",
            isARepeat: isRepeat,
            keyCode: 1
        ))
    }

    #expect(LocalShortcuts.Name.handle(event: try event(.keyDown)) == false)
    #expect(LocalShortcuts.Name.handle(event: try event(.keyDown, timestamp: 0.5)) == false)
    #expect(LocalShortcuts.Name.handle(event: try event(.keyDown, repeat: true, timestamp: 1.0)) == false)
    #expect(invocationCount == 1)

    #expect(LocalShortcuts.Name.handle(event: try event(.keyDown, timestamp: 2.1)) == false)
    #expect(invocationCount == 2)
    #expect(LocalShortcuts.Name.handle(event: try event(.keyUp, timestamp: 2.2)) == false)
    #expect(LocalShortcuts.Name.handle(event: try event(.keyDown, timestamp: 2.3)) == false)
    #expect(invocationCount == 3)
    _ = LocalShortcuts.Name.handle(event: try event(.keyUp, timestamp: 2.4))
}
