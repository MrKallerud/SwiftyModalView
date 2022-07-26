//
//  ModalScrollView.swift
//
//  Created by Ole Kallerud on 20/07/2022.
//

import SwiftUI
import SwiftUIVisualEffects

/// A custom modal view with multiple height presets.
@available(iOS 13.0, *)
public struct ModalScrollView<Content: View>: View {
    // Settings
    private let material: UIBlurEffect.Style
    private let cornerRadius: Double
    private let handleStyle: HandleStyle
    private let backgroundShadow: Double
    private let animation: Animation
    private let resizable: Bool
    private let minSize: CGFloat
    private let content: (_ position: Double) -> Content
    
    // Technical values
    @State private var dragOffset: CGFloat = UIScreen.height * 1.3
    @State private var prevOffset: CGFloat = .zero
    @State private var prevDragTranslation: CGSize = .zero
    @State private var modalSize: CGFloat = .zero
    private var dragPrecentage: Double {
        max(0, min(1, (1 - ((dragOffset - ModalPosition.fill.offset()) / (ModalPosition.hidden.offset() - ModalPosition.fill.offset())))))
    }
    
    public init(
        material: UIBlurEffect.Style = .systemMaterial,
        cornerRadius: Double = 20,
        handleStyle: HandleStyle = .medium,
        backgroundShadow: Double = 0.3,
        animation: SwiftyAnimation = .standard,
        resizable: Bool = false,
        minSize: ModalPosition = .middle,
        content: @escaping (_ position: Double) -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.handleStyle = handleStyle
        self.backgroundShadow = backgroundShadow
        self.animation = animation.animation
        self.resizable = resizable
        self.minSize = minSize.offset()
        self.content = content
    }
    
    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                let dragAmount = value.translation.height - prevDragTranslation.height
                dragOffset += dragAmount
                prevDragTranslation.height = value.translation.height
            }
            .onEnded { value in
                prevDragTranslation = .zero
                // dragOffset = min(max(dragOffset, UIScreen.height - modalSize), ModalPosition.bottom.offset())
                prevOffset = dragOffset
            }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .opacity(dragPrecentage * backgroundShadow)
                .animation(.easeInOut(duration: 0.1), value: dragPrecentage)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // dragOffset = ModalPosition.bottom.offset()
                }
            
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    if handleStyle != .none {
                        Color.primary
                            .opacity(0.5)
                            .frame(width: handleStyle.width(), height: 6)
                            .clipShape(Capsule())
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    
                    content(dragPrecentage)
//                        .padding(.top, min(UIApplication.topInset ?? 42, max(22, (UIApplication.topInset ?? 42) - offset)))
//                        .padding(.bottom, UIApplication.bottomInset ?? 42)
//                        .padding(.bottom, resizable ?
//                                 max(.zero, min(offset, minSize)) : .zero)
//                        .frame(minHeight: .zero)
                    Spacer(minLength: .zero)
                }
                .frame(width: UIScreen.width, height: UIScreen.height * 1.3)
            }
            .background(
                BlurEffect()
                    .onTapGesture {
                        withAnimation(animation) {
                            // dragOffset = ModalPosition.top.offset()
                        }
                    }
            )
            //.cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
            // .offset(y: max(dragOffset, UIScreen.height - modalSize))
            .offset(y: max(.zero, dragOffset))
            .gesture(dragGesture)
            .edgesIgnoringSafeArea(.vertical)
        }
//        .shadow(color: .black.opacity(1/3), radius: 20)
        .onAppear {
            dragOffset = UIScreen.height / 1.3
        }
//        .blurEffectStyle(material)
    }
}

@available(iOS 15.0, *)
struct ModalScrollView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1593558628703-535b2556320b?auto=format&fit=crop&h=500&q=50")) { image in
                image.resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .frame(width: UIScreen.width)
            } placeholder: {
                ProgressView()
            }
            ModalScrollView { position in
                ZStack {
                    VStack {
                        Text("SwiftyModalView")
                            .font(.largeTitle)
                        Text("MATERIAL")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .opacity(0.5)
                .background(Color.gray)
            }
        }
    }
}
