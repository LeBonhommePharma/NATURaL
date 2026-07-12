public actor AlexaBTGroup {
    static let shared = AlexaBTGroup()

    public func syncAllAlexaBT(bpm: Double, sigma: Double) async {
        await AlexaAPI.shared.setAllDevicesVolume(0.85)
        await AlexaAPI.shared.playOnLinkedBluetoothSpeaker("coherent-beat", bpm: bpm)
        if sigma > 0.15 {
            await AlexaAPI.shared.triggerGroundingRoutineOnAll("breathe + lights")
        }
        await CrownController.shared.broadcastBeat(bpm: bpm, beta: ThermodynamicState.shared.beta)
        print("🔊 Alexa + BT Speakers fully in Clusterfuck")
    }
}