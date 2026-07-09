// Swift bridge to optimized kernel
public func optimizeAndApplySync() async {
    let optimizedDelay = EigenMetalBridge.shared.optimizeAudioSync(latencies: currentLatencies, sigma: CrooksCycleController.shared.sigmaIrr)
    await applyDelay(optimizedDelay)
}