//
//  Extensions.swift
//  
//
//  Created by Ole Kallerud on 20/07/2022.
//

import SwiftUI

/// Various custom animations that fits the SwiftyModelView.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public enum SwiftyAnimation {
    /// The default animation that is relatively slow and with a very small amount of bounce.
    case standard
    
    /// A quick animation with a little bit of bounce.
    case quick
    
    /// A very bouncy animation that fits best without the top position.
    case bounce
    
    /// Simple ease-out bezier curve without bounce.
    /// Preview: https://cubic-bezier.com/#0,0,0,1
    case simple
    
    /// Insert your own custom animations.
    case custom(_ animation: Animation)
    
    /// Returns the animation object.
    public var animation: Animation {
        switch self {
            /// Returns the animation: ".interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 15)"
        case .standard:
            return .interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 15)
            
            /// Returns the animation: ".interpolatingSpring(stiffness: 1000, damping: 55, initialVelocity: 30)"
        case .quick:
            return .interpolatingSpring(stiffness: 1000, damping: 55, initialVelocity: 30)
            
            /// Returns the animation: ".interpolatingSpring(stiffness: 500, damping: 28, initialVelocity: 5)"
        case .bounce:
            return .interpolatingSpring(stiffness: 500, damping: 28, initialVelocity: 5)
            
        case .simple:
            return .timingCurve(0, 0, 0, 1, duration: 0.3)
            /// Returns the animation passed in the argument.
        case .custom(let animation):
            return animation
        }
    }
}

/// Various positions for the modal.
public enum ModalPosition: Comparable, Hashable {
    /// Fills the entire view
    case fill
    
    /// Positions the modal at the top of the safe area.
    case top
    
    /// Positions the modal right below the middle of the screen
    case middle
    
    /// Positions the modal at the bottom of the screen.
    case bottom
    
    /// Positions the modal below the screen, out of sight.
    case hidden
    
    /// Positions the modal at the position of the argument.
    /// Pass a value between 0 and 1, 0 is hidden and 1 is the top.
    case custom(_ position: CGFloat)
    
    /// Returns the height value for the position.
    func offset() -> CGFloat {
        switch self {
        case .fill:
            return .zero
        case .top:
            return UIApplication.topInset ?? 42
        case .middle:
            return UIScreen.height / 2
        case .bottom:
            return UIScreen.height - (UIApplication.bottomInset ?? 32) - 42
        case .hidden:
            return UIScreen.height
        case .custom(let position):
            return UIScreen.height * (1 - position)
        }
    }
    
    public static func <(lhs: ModalPosition, rhs: ModalPosition) -> Bool {
        return lhs.offset() < rhs.offset()
    }
}

internal extension UIApplication {
    static var topInset: CGFloat? {
        shared.windows.first{$0.isKeyWindow }?.safeAreaInsets.top
    }
    static var bottomInset: CGFloat? {
        shared.windows.first{$0.isKeyWindow }?.safeAreaInsets.bottom
    }
}

/// Various sets of modal positons.
public enum ModalPositionSet {
    /// The standard set of positions:
    /// .bottom, .middle, .top
    case standard
    
    /// A dismissable version of the standard set:
    /// .hidden, .bottom, .middle, .top
    case dismissable
    
    case fill(_ dismissable: Bool = true)
    
    /// Just the bottom and top positions:
    case simple(_ dismissable: Bool = true)
    
    /// Just the bottom and middle positions:
    case low(_ dismissable: Bool = true)
    
    /// A set of positions all over the screen, allowing the modal to be placed nearly anywhere.
    case all(_ dismissable: Bool = false)
    
    /// Make your own custom set of positions
    case custom(_ positions: Set<ModalPosition>)
    
    func set() -> Set<ModalPosition> {
        switch self {
        case .standard:
            return [.bottom, .middle, .top]
        case .dismissable:
            return [.hidden, .bottom, .middle, .top]
        case .fill(let dismissable):
            return dismissable ? [.hidden, .bottom, .fill] : [.bottom, .fill]
        case .simple(let dismissable):
            return dismissable ? [.hidden, .bottom, .top] : [.bottom, .top]
        case .low(let dismissable):
            return dismissable ? [.hidden, .bottom, .middle] : [.bottom, .middle]
        case .all(let dismissable):
            var all: Set<ModalPosition> = [
                .bottom,
                .custom(0.2),
                .custom(0.3),
                .custom(0.4),
                .middle,
                .custom(0.6),
                .custom(0.7),
                .custom(0.8),
                .custom(0.9),
                .top,
                .fill
            ]
            if dismissable { all.insert(.hidden) }
            return all
        case .custom(let positions):
            return positions
        }
    }
}

/// Various styles for the handle at the top of the modal.
public enum HandleStyle {
    case none
    case small
    case medium
    case large
    
    func width() -> CGFloat {
        switch self {
        case .none:
            return .zero
        case .small:
            return 24
        case .medium:
            return 48
        case .large:
            return 64
        }
    }
}

internal extension Collection where Element == ModalPosition {
    func getLowest() -> Element {
        let sorted = self.sorted()
        if sorted.last != .hidden {
            return sorted.last ?? .bottom
        }
        return sorted.dropLast().last ?? .bottom
    }
    
    func getHighest() -> Element {
        self.sorted().first ?? .bottom
    }
    
    func isSinglePosition() -> Bool {
        (!self.contains(.hidden) && self.count <= 1) ||
        (self.contains(.hidden) && self.count <= 2)
    }
}

internal extension UIScreen {
    static let width = UIScreen.main.bounds.size.width
    static let height = UIScreen.main.bounds.size.height
    static let size = UIScreen.main.bounds.size
}

internal extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
