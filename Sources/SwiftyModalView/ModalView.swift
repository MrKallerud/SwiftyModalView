//
//  ModalView.swift
//
//  Created by Ole Kallerud on 19/07/2022.
//

import SwiftUI

/// A custom modal view with multiple height presets.
@available(iOS 13.0, *)
public struct SwiftyModalView<Content: View>: View {
    // Settings
    @State private var position: ModalPosition = .hidden
    private let availablePositions: Set<ModalPosition>
    private let backgroundColor: UIColor
    private let cornerRadius: Double
    private let handleStyle: HandleStyle
    private let backgroundDarkness: Double
    private let animation: Animation
    private let content: (_ position: Double) -> Content
        
    // Technical values
    @State private var dragOffset: CGFloat = .zero
    @State private var prevOffset: CGFloat = .zero
    @State private var prevDragTranslation: CGSize = .zero
    private var offset: CGFloat { position.offset() + dragOffset }
    private var dragPrecentage: Double {
        max(0, min(1, (1 - ((offset - availablePositions.getHighest().offset()) / (availablePositions.getLowest().offset() - availablePositions.getHighest().offset())))))
    }
    
    public init(
        position: ModalPosition? = nil,
        availablePositions: ModalPositionSet = .dismissable,
        backgroundColor: UIColor = .secondarySystemBackground,
        cornerRadius: Double = 20,
        handleStyle: HandleStyle = .medium,
        backgroundDarkness: Double = 0.5,
        animation: SwiftyAnimation = .standard,
        content: @escaping (_ position: Double) -> Content
    ) {
        self.position = position ?? availablePositions.set().getHighest()
        self.availablePositions = availablePositions.set()
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
                    
                    if offset > availablePositions.getLowest().offset() || offset < availablePositions.getHighest().offset() {
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
                        distances[abs((offset + (value.predictedEndTranslation.height * 0.9)) - position.offset())] = position
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
                .opacity(position == .hidden ?
                            0 : // If hidden
                            (availablePositions.isSinglePosition() ? // If not hidden
                                backgroundDarkness : // If single position
                                (dragPrecentage * backgroundDarkness))) // If multiple positions
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
                                .padding([.top, .horizontal])
                        }
                    }
                    
                    content(dragPrecentage)
                    
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

struct SwiftyModalView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftyModalView(availablePositions: .standard) { position in
            Text("\(position)").padding()
        }
    }
}
