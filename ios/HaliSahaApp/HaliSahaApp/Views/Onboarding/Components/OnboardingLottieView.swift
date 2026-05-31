//
//  OnboardingLottieView.swift
//  HaliSahaApp
//
//  Onboarding ekranlarında kullanılan Lottie sarmalayıcısı.
//  LottieAnimationView'in kendi intrinsic content size'ı SwiftUI frame'ini
//  bazen ezdiği için bir container UIView içine hapsediyoruz.
//

import SwiftUI
import Lottie

struct OnboardingLottieView: UIViewRepresentable {

    let animationName: String
    var loopMode: LottieLoopMode = .loop
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.clipsToBounds = true
        container.setContentHuggingPriority(.defaultLow, for: .horizontal)
        container.setContentHuggingPriority(.defaultLow, for: .vertical)
        container.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        container.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let animationView = LottieAnimationView(name: animationName)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.animationSpeed = 1.0
        animationView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        animationView.play()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = uiView.subviews.first as? LottieAnimationView else { return }
        if !animationView.isAnimationPlaying {
            animationView.play()
        }
    }
}
