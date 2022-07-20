//
//  ModalView.swift
//
//  Created by Ole Kallerud on 19/07/2022.
//

import SwiftUI

/// A custom modal view with multiple height presets.
@available(iOS 15.0, *)
public struct MaterialModalView<Content: View>: View {
    // Settings
    @State private var position: ModalPosition = .hidden
    private let availablePositions: Set<ModalPosition>
    private let material: Material
    private let cornerRadius: Double
    private let handleStyle: HandleStyle
    private let backgroundShadow: Double
    private let animation: Animation
    private let resizable: Bool
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
        availablePositions: ModalPositionSet = .dismissable,
        material: Material = .regular,
        cornerRadius: Double = 20,
        handleStyle: HandleStyle = .medium,
        backgroundShadow: Double = 0,
        animation: SwiftyAnimation = .standard,
        resizable: Bool = false,
        content: @escaping (_ position: Double) -> Content
    ) {
        self.availablePositions = availablePositions.set()
        self.material = material
        self.cornerRadius = cornerRadius
        self.handleStyle = handleStyle
        self.backgroundShadow = backgroundShadow
        self.animation = animation.animation
        self.resizable = resizable
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
                    let sensitivity = max(1, availablePositions.count / 7)
                    prevDragTranslation = .zero
                    dragOffset = .zero
                    
                    var distances = [CGFloat: ModalPosition]()
                    for position in availablePositions {
                        distances[abs((offset + (value.predictedEndTranslation.height * CGFloat(sensitivity))) - position.offset())] = position
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
                          backgroundShadow : // If single position
                          (dragPrecentage * backgroundShadow))) // If multiple positions
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
                        //.padding(.bottom, position == .fill ? 0 : (UIApplication.topInset ?? 42))
                        .padding(.bottom, resizable ?
                                    offset :
                                    (availablePositions.contains(.fill) ? 0 : (UIApplication.topInset ?? 42)))
                        .frame(minHeight: .zero)
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: UIScreen.width, maxHeight: .infinity)
                .background(
                    Color.clear
                        .background(material)
                        .onTapGesture {
                            withAnimation(animation) {
                                position = availablePositions.getHighest()
                            }
                        }
                )
                .cornerRadius(min(offset, cornerRadius),
                              corners: [.topLeft, .topRight])
                .offset(y: max(.zero, offset))
                .gesture(dragGesture)
                .edgesIgnoringSafeArea(.vertical)
            }
        }
        .shadow(color: .black.opacity(1/3), radius: 20)
        .onAppear {
            withAnimation(animation) {
                position = availablePositions.getHighest()
            }
        }
    }
}

@available(iOS 15.0, *)
struct MaterialModalView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1593558628703-535b2556320b?auto=format&fit=crop&h=2000&q=90")) { image in
                image.resizable().scaledToFill()
                    .ignoresSafeArea()
            } placeholder: {
                ProgressView()
            }
            MaterialModalView(availablePositions: .standard) { position in
                ZStack {
                    Color.red
                    Text("\(position)").padding()
                }
                .frame(height: 100)
                .cornerRadius(20)
                .padding()
            }
        }.preferredColorScheme(.dark)
    }
}
