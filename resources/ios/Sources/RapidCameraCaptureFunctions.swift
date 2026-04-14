import Foundation
import UIKit

enum RapidCameraCaptureFunctions {

    class OpenCamera: BridgeFunction {
        func execute(parameters: [String: Any]) throws -> [String: Any] {
            DispatchQueue.main.async {
                let cameraVC = RapidCameraCaptureViewController()
                cameraVC.modalPresentationStyle = .fullScreen

                // Traverse to the topmost presented view controller
                let keyWindow = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }

                var topVC = keyWindow?.rootViewController
                while let presented = topVC?.presentedViewController {
                    topVC = presented
                }

                topVC?.present(cameraVC, animated: true)
            }

            return BridgeResponse.success(data: ["status": "opening"])
        }
    }
}
