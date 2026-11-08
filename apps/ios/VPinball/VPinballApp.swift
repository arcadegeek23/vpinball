import Foundation
import SwiftUI

struct VPinballAppView: View {
    @ObservedObject var vpinballModel = VPinballModel.shared

    var body: some View {
        ZStack {
            if vpinballModel.showSplash {
                SplashView()
                    .onAppear {
                        handleAppear()
                    }
            } else {
                MainView()
                    .opacity(vpinballModel.showMainView ? 1 : 0)
            }

            if vpinballModel.isPlaying && vpinballModel.showGameMenu {
                GameMenuView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: vpinballModel.showGameMenu)
        .onChange(of: vpinballModel.isPlaying) {
            vpinballModel.showMainView = !vpinballModel.isPlaying

            StatusBarManager.shared.setHidden(!vpinballModel.showMainView,
                                              animated: false)
            StatusBarManager.shared.setOrientationLocked(vpinballModel.isPlaying)
        }
    }

    func handleAppear() {
        VPinballManager.shared.startup()
        AppAppearance.current.apply()
        vpinballModel.startSplashTimer()
    }
}
