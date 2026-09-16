import SwiftUI
import TipKit
import BonhommeCore

/// On-session TipKit cards. Configured from `BonhommeApp`; never blocks a pose timer.
struct SessionSCITip: Tip {
    var title: Text {
        Text(LocalizedString(
            en: "Your focus index",
            fr: "Votre indice de concentration"
        ).localized)
    }

    var message: Text {
        Text(LocalizedString(
            en: "SCI is Shannon entropy of heart-rate variability, computed on this device. Violet is focused; mint is coherent. It is not a diagnosis.",
            fr: "Le SCI est l’entropie de Shannon de la variabilité cardiaque, calculée sur cet appareil. Violet = concentré; menthe = cohérent. Ce n’est pas un diagnostic."
        ).localized)
    }

    var image: Image? {
        Image(systemName: "waveform.path.ecg")
    }
}

struct SessionAirPodsTip: Tip {
    var title: Text {
        Text(SessionHUDCopy.airPods.localized)
    }

    var message: Text {
        Text(LocalizedString(
            en: "AirPods volume steers session intensity. Head motion keeps spatial audio with you. NATURaL never ramps system volume.",
            fr: "Le volume des AirPods oriente l’intensité. Le mouvement de la tête suit l’audio spatial. NATURaL ne règle jamais le volume système."
        ).localized)
    }

    var image: Image? {
        Image(systemName: "airpodspro")
    }
}

struct SessionARCoachTip: Tip {
    var title: Text {
        Text(SessionHUDCopy.arCoach.localized)
    }

    var message: Text {
        Text(LocalizedString(
            en: "When the camera can track the room, a 3D figure coaches the pose. Without AR hardware or permission, the 2D coach is used instead. Video stays on this device.",
            fr: "Quand la caméra peut suivre la pièce, une silhouette 3D guide la pose. Sans AR ou sans permission, le coach 2D s’affiche. La vidéo reste sur cet appareil."
        ).localized)
    }

    var image: Image? {
        Image(systemName: "camera.viewfinder")
    }
}

enum SessionTips {
    static let sci = SessionSCITip()
    static let airPods = SessionAirPodsTip()
    static let arCoach = SessionARCoachTip()
}
