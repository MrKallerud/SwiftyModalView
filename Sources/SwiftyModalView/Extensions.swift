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
    
    /// Insert your own custom animations.
    case custom(animation: Animation)
    
    /// Returns the animation object.
    public var animation: Animation {
        switch self {
            
            /// Returns the animation: ".interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 15)"
        case .standard:
            return .interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 15)
            
            /// Returns the animation: ".interpolatingSpring(stiffness: 1500, damping: 40, initialVelocity: 40)"
        case .quick:
            return .interpolatingSpring(stiffness: 1000, damping: 50, initialVelocity: 30)
            
            /// Returns the animation: ".interpolatingSpring(stiffness: 600, damping: 28, initialVelocity: 20)"
        case .bounce:
            return .interpolatingSpring(stiffness: 600, damping: 28, initialVelocity: 20)
            
            /// Returns the animation passed in the argument.
        case .custom(let animation):
            return animation
        }
    }
}

/// Various positions for the modal.
public enum ModalPosition: Comparable {
    /// Positions the modal at the top of the safe area.
    case top
    
    /// Positions the modal right below the middle of the screen
    case middle
    
    /// Positions the modal at the bottom of the screen.
    case bottom
    
    /// Positions the modal below the screen, out of sight.
    case hidden
    
    /// Positions the modal at the position of the argument.
    /// Pass a value between 0.0 and 1.0.
    case custom(position: CGFloat)
    
    /// Returns the height value for the position.
    func offset() -> CGFloat {
        switch self {
        case .top:
            return .zero
        case .middle:
            return UIScreen.height / 2
        case .bottom:
            return UIScreen.height - 128
        case .hidden:
            return UIScreen.height
        case .custom(let position):
            return UIScreen.height * position
        }
    }
    
    public static func <(lhs: ModalPosition, rhs: ModalPosition) -> Bool {
        return lhs.offset() < rhs.offset()
    }
}

/// Various styles for the handle at the top of the modal.
public enum HandleStyle {
    case none, small, medium, large
    
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
        self.sorted().last ?? .bottom
    }
    
    func getHighest() -> Element {
        self.sorted().first ?? .top
    }
}

private extension UIScreen {
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
