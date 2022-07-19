//
//  ModalView.swift
//
//  Created by Ole Kallerud on 19/07/2022.
//

import SwiftUI

@available(iOS 13.0, *)
public struct ModalView<Content: View>: View {
    
//    var material: Material = .ultraThinMaterial
    
    // Settings
    @State var position: ModalPosition = .bottom
    var availablePositions: [ModalPosition] = [.top, .middle, .bottom, .hidden]
    var backgroundColor: UIColor = .secondarySystemBackground
    var cornerRadius: Double = 20
    var handleStyle: HandleStyle = .medium
    var backgroundDarkness: Double = 1/2
    var animation: Animation { .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0) }
    let content: (_ position: String) -> Content
    
    // Technical values
    @State private var dragOffset: CGFloat = .zero
    @State private var prevOffset: CGFloat = .zero
    @State private var prevDragTranslation: CGSize = .zero
    private var offset: CGFloat { position.offset() + dragOffset }
    private var dragPrecentage: Double {
        return max(0, min(1, (1 - ((offset - ModalPosition.top.offset()) / (ModalPosition.bottom.offset() - ModalPosition.top.offset())))))
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
                        distances[abs((offset + value.predictedEndTranslation.height) - position.offset())] = position
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
//            .frame(maxWidth: .infinity)
        .shadow(color: .black.opacity(1/3), radius: 20)
//            .onAppear {
//                zOffset = lowHeight
//                prevOffset = lowHeight
//            }
//            .onDisappear { zOffset = UIScreen.height }
        .opacity(position == .hidden ? 0 : 1)
    }
}

enum ModalPosition: Comparable {
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
    
    static func <(lhs: ModalPosition, rhs: ModalPosition) -> Bool {
        return lhs.order < rhs.order
    }
}

enum HandleStyle {
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

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView { position in
            Text("\(position)")
            //Color.red
        }
    }
}
