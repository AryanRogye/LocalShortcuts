#if os(macOS)
import AppKit

public enum LocalShortcuts {
    public struct Name: Hashable, Codable {
        
        public typealias Handler = () -> Void
        typealias LocalMonitor = Any
        public let rawValue: String
        public let defaultShortcut: Shortcut

        @MainActor internal static var monitor: LocalMonitor?
        
        @MainActor internal static var shortcuts: [Name: Shortcut] = [:]
        @MainActor internal static var handlers:  [Name: Handler] = [:]
        @MainActor internal static var keyUpHandlers: [Name: Handler] = [:]
        @MainActor internal static var consumesEvents: [Name: Bool] = [:]
        @MainActor internal static var allowsRepeat: [Name: Bool] = [:]
        @MainActor private static var pressedKeys: [UInt16: (lastEventTime: TimeInterval, modifiers: NSEvent.ModifierFlags)] = [:]
        @MainActor private static var activeKeyUps: [UInt16: Name] = [:]
        @MainActor private static var activeModifierShortcuts: Set<Name> = []
        @MainActor private static var deactivateObserver: NSObjectProtocol?

        /// Registers with null
        @MainActor public init(_ rawValue: String, _ shortcut: Shortcut) {
            self.rawValue = rawValue
            self.defaultShortcut = shortcut
            Self.shortcuts[self] = shortcut
        }
        
        @MainActor public static func onKeyDown(
            for name: Name,
            consumesEvent: Bool = false,
            allowsRepeat: Bool = true,
            completion: @escaping Handler
        ) {
            handlers[name] = completion
            consumesEvents[name] = consumesEvent
            Self.allowsRepeat[name] = allowsRepeat
            startMonitorIfNeeded()
        }

        /// Called once when a shortcut ends after a matching key down.
        /// For shortcuts with modifiers, this happens when a required modifier is released.
        /// For shortcuts without modifiers, this happens when the main key is released.
        @MainActor public static func onKeyUp(for name: Name, completion: @escaping Handler) {
            keyUpHandlers[name] = completion
            startMonitorIfNeeded()
        }
        
        @MainActor private static func startMonitorIfNeeded() {
            guard Name.monitor == nil else { return }
            
            Name.monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { event in
                handle(event: event) ? nil : event
            }

            deactivateObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    pressedKeys.removeAll()
                    activeKeyUps.removeAll()
                    activeModifierShortcuts.removeAll()
                }
            }
        }
        
        @MainActor
        internal static func handle(event: NSEvent) -> Bool {
            if event.type == .keyUp {
                pressedKeys[event.keyCode] = nil
                if let name = activeKeyUps.removeValue(forKey: event.keyCode) {
                    keyUpHandlers[name]?()
                }
                return false
            }
            if event.type == .flagsChanged {
                pressedKeys = pressedKeys.filter { _, pressed in
                    event.modifierFlags.contains(pressed.modifiers)
                }
                let released = activeModifierShortcuts.filter { name in
                    shortcuts[name]?.modifier.contains { modifier in
                        !event.modifierFlags.contains(modifier.flag)
                    } ?? true
                }
                for name in released {
                    activeModifierShortcuts.remove(name)
                    keyUpHandlers[name]?()
                }
                return false
            }
            guard event.type == .keyDown else { return false }

            guard let eventShortcut = Shortcut.from(event: event) else {
                return false
            }

            guard let (name, shortcut) = shortcuts.first(where: {
                $0.value == eventShortcut
            }), handlers[name] != nil || keyUpHandlers[name] != nil else {
                return false
            }

            if keyUpHandlers[name] != nil {
                if shortcut.modifier.isEmpty {
                    activeKeyUps[event.keyCode] = name
                } else {
                    activeModifierShortcuts.insert(name)
                }
            }

            if allowsRepeat[name] == false {
                // WebKit can leave us without a matching key-up. Releasing a
                // modifier or a pause in key-down events also ends the press.
                let previous = pressedKeys[event.keyCode]
                let modifiers = event.modifierFlags.intersection([
                    .command, .shift, .option, .control, .capsLock
                ])
                pressedKeys[event.keyCode] = (event.timestamp, modifiers)
                let isNewPress = previous.map { event.timestamp - $0.lastEventTime >= 1 } ?? true
                guard !event.isARepeat,
                      isNewPress else {
                    return false
                }
            }

            handlers[name]?()

            return consumesEvents[name] ?? false
        }
    }
    
    public struct Shortcut: Codable, Hashable {
        public var modifier: [Modifier]
        public var keys: [Key]
        
        public init(modifier: [Modifier], keys: [Key]) {
            self.modifier = modifier
            self.keys = keys
        }
        
        @MainActor public func keysContains(_ keysToCheck: Key...) -> Bool {
            for key in keysToCheck {
                if keys.contains(key) {
                    continue
                }
                return false
            }
            return true
        }
        
        @MainActor public func capitalKeys() -> Self? {
            let mappedKeys = keys.map { $0.capital }
            if mappedKeys.contains(where: { $0 == nil }) {
                return nil
            }
            let unwrappedKeys = mappedKeys.compactMap { $0 }
            return .init(modifier: modifier, keys: unwrappedKeys)
        }
        
        @MainActor public func lowerCaseKeys() -> Self? {
            let mappedKeys = keys.map { $0.lowerCase }
            if mappedKeys.contains(where: { $0 == nil }) {
                return nil
            }
            let unwrappedKeys = mappedKeys.compactMap { $0 }
            return .init(modifier: modifier, keys: unwrappedKeys)
        }
        
        /// Convenience to build a shortcut from an event. Returns `nil` if no key could be parsed.
        @MainActor public static func from(event: NSEvent) -> Shortcut? {
            let modifiers = LocalShortcuts.Modifier.activeModifiers(from: event)
            let keys = LocalShortcuts.Key.activeKeys(event: event)
            
            guard !keys.isEmpty else { return nil }
            return Shortcut(modifier: modifiers, keys: keys)
        }
        
        /// Backwards-compatible helper; prefer `from(event:)` when you need to validate.
        @MainActor public static func getShortcut(event: NSEvent) -> Shortcut {
            if let shortcut = from(event: event) {
                return shortcut
            }
            
            // Fallback to the previous behavior (empty keys) so existing callers keep working.
            let modifiers = LocalShortcuts.Modifier.activeModifiers(from: event)
            let keys = LocalShortcuts.Key.activeKeys(event: event)
            
            return Shortcut(modifier: modifiers, keys: keys)
        }
        
        @MainActor
        public func modifiers() -> String {
            modifier.map { $0.rawValue }.joined()
        }
        
        @MainActor
        public func keyValues() -> String {
            keys.map { $0.rawValue }.joined()
        }
        
        /// Human-friendly representation used in UI labels.
        @MainActor
        public func displayValue() -> String {
            [modifiers(), keyValues()]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }
}

public extension Set where Element == LocalShortcuts.Shortcut {
    func contains(_ modifier: LocalShortcuts.Modifier) -> Bool {
        contains { $0.modifier.contains(modifier) }
    }
    func contains(_ key: LocalShortcuts.Key) -> Bool {
        contains { $0.keys.contains(key) }
    }
    func keysContains(_ keysToCheck: LocalShortcuts.Key...) -> Bool {
        allSatisfy { shortcut in
            shortcut.keys.contains { keysToCheck.contains($0) }
        }
    }
}


public extension Array where Element == LocalShortcuts.Shortcut {
    func contains(_ modifier: LocalShortcuts.Modifier) -> Bool {
        contains { $0.modifier.contains(modifier) }
    }
    func contains(_ key: LocalShortcuts.Key) -> Bool {
        contains { $0.keys.contains(key) }
    }
    func keysContains(_ keysToCheck: LocalShortcuts.Key...) -> Bool {
        allSatisfy { shortcut in
            shortcut.keys.contains { keysToCheck.contains($0) }
        }
    }
}
#endif
