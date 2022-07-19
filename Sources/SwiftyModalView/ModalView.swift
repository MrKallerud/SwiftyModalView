//
//  ModalView.swift
//
//  Created by Ole Kallerud on 19/07/2022.
//

import SwiftUI

@available(iOS 13.0, *)
public struct SwiftyModalView<Content: View>: View {
    
//    var material: Material = .ultraThinMaterial
    
    // Settings
    @Binding private var position: ModalPosition
    private let availablePositions: Set<ModalPosition>
    private let backgroundColor: UIColor
    private let cornerRadius: Double
    private let handleStyle: HandleStyle
    private let backgroundDarkness: Double
    private let animation: Animation
    private let content: (_ position: String) -> Content
    
    public let defaultAnimation: Animation = .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)
    
    // Technical values
    @State private var dragOffset: CGFloat = .zero
    @State private var prevOffset: CGFloat = .zero
    @State private var prevDragTranslation: CGSize = .zero
    private var offset: CGFloat { position.offset() + dragOffset }
    private var dragPrecentage: Double {
        return max(0, min(1, (1 - ((offset - ModalPosition.top.offset()) / (ModalPosition.bottom.offset() - ModalPosition.top.offset())))))
    }
    
    public init(
        _ position: Binding<ModalPosition>,
        availablePositions: Set<ModalPosition> = [.top, .middle, .bottom, .hidden],
        backgroundColor: UIColor = .secondarySystemBackground,
        cornerRadius: Double = 20,
        handleStyle: HandleStyle = .medium,
        backgroundDarkness: Double = 0.5,
        animation: SwiftyAnimation = .standard,
        content: @escaping (_ position: String) -> Content
    ) {
        self._position = position
        self.availablePositions = availablePositions
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.handleStyle = handleStyle
        self.backgroundDarkness = backgroundDarkness
        self.animation = animation.animation
        self.content = content
    }
    
    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                withAnimation(animation) {
                    let dragAmount = value.translation.height - prevDragTranslation.height
                    
                    if offset > availablePositions.getLowest().offset() || offset > availablePositions.getHighest().offset() {
                        dragOffset += dragAmount / 5
                    } else {
                        dragOffset += dragAmount
                    }
                    
                    prevDragTranslation.height = value.translation.height
                }
            }
            .onEnded { value in
                withAnimation(animation) {
                    prevDragTranslation = .zero
                    dragOffset = .zero
                    
                    var distances = [CGFloat: ModalPosition]()
                    for position in availablePositions {
                        distances[abs((offset + (value.predictedEndTranslation.height / 2)) - position.offset())] = position
                    }
                    let nearestPosition = distances[distances.keys.sorted().first ?? 0] ?? .bottom
                    
                    if nearestPosition == .hidden && position != availablePositions.getLowest() {
                        position = availablePositions.getLowest()
                    } else {
                        position = nearestPosition
                    }
                    prevOffset = dragOffset
                }
                
            }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(dragPrecentage * backgroundDarkness)
                .animation(.easeInOut(duration: 0.1), value: dragPrecentage)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(animation) {
                        if availablePositions.contains(.bottom) {
                            position = .bottom
                        } else if availablePositions.contains(.middle) {
                            position = .middle
                        }
                    }
                }
            
            VStack {
                VStack(spacing: 0) {
                    if handleStyle != .none {
                        ZStack {
                            Color.primary
                                .opacity(0.5)
                                .frame(width: handleStyle.width(), height: 6)
                                .clipShape(Capsule())
                                .padding()
                        }
                    }
                    
                    content(String(dragPrecentage))
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Color(backgroundColor)
                        .onTapGesture {
                            withAnimation(animation) {
                                position = availablePositions.getHighest()
                            }
                        }
                )
                .cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
                .offset(y: max(.zero, offset))
                .gesture(dragGesture)
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .shadow(color: .black.opacity(1/3), radius: 20)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public enum SwiftyAnimation {
    case standard, quick, bounce, custom(animation: Animation)
    
    public var animation: Animation {
        switch self {
        case .standard:
            return .interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 15)
        case .quick:
            return .interpolatingSpring(stiffness: 1500, damping: 40, initialVelocity: 40)
        case .bounce:
            return .interpolatingSpring(stiffness: 600, damping: 28, initialVelocity: 20)
        case .custom(let animation):
            return animation
        }
    }
}

public enum ModalPosition: Comparable {
    case top, middle, bottom, hidden
    
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
        }
    }
    
    private var order: Int {
        switch self {
        case .hidden:
            return 0
        case .top:
            return 1
        case .middle:
            return 2
        case .bottom:
            return 3
        }
    }
    
    public static func <(lhs: ModalPosition, rhs: ModalPosition) -> Bool {
        return lhs.order < rhs.order
    }
}

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

private extension Collection where Element == ModalPosition {
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

private extension View {
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

struct SwiftyModalView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftyModalView(.constant(.middle), animation: .standard) { position in
            Text("\(position)")
            //Color.red
        }
    }
}
