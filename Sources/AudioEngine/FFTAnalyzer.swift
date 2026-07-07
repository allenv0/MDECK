import AVFoundation
import Accelerate

final class FFTAnalyzer {
    let fftSize: Int
    let bandCount: Int
    private let minBin = 2
    private let fftSetup: FFTSetup
    private let window: [Float]

    init(fftSize: Int = 1024, bandCount: Int = 16) {
        self.fftSize = fftSize
        self.bandCount = bandCount
        let log2n = vDSP_Length(log2(Float(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        var w = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&w, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        window = w
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    func process(_ buffer: AVAudioPCMBuffer) -> (bands: [Float], level: Float) {
        guard let ch = buffer.floatChannelData else { return (bands: .init(repeating: 0, count: bandCount), level: 0) }
        let n = min(Int(buffer.frameLength), fftSize)
        guard n == fftSize else { return (bands: .init(repeating: 0, count: bandCount), level: 0) }
        let samples = ch[0]

        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(samples, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(fftSize))

        let half = fftSize / 2
        var real = [Float](repeating: 0, count: half)
        var imag = [Float](repeating: 0, count: half)
        var magnitudes = [Float](repeating: 0, count: half)
        windowed.withUnsafeBufferPointer { ptr in
            real.withUnsafeMutableBufferPointer { rp in
                imag.withUnsafeMutableBufferPointer { ip in
                    var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                    ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: half) { typed in
                        vDSP_ctoz(typed, 2, &split, 1, vDSP_Length(half))
                    }
                    vDSP_fft_zrip(fftSetup, &split, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))
                    vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(half))
                }
            }
        }

        var out = [Float](repeating: 0, count: bandCount)
        for b in 0..<bandCount {
            let lo = Int(Double(half - minBin) * pow(Double(b) / Double(bandCount), 2.0)) + minBin
            let hi = Int(Double(half - minBin) * pow(Double(b + 1) / Double(bandCount), 2.0)) + minBin
            let a = max(minBin, lo), z = max(a + 1, min(half, hi))
            var sum: Float = 0
            for i in a..<z { sum += magnitudes[i] }
            let meanPower = sum / Float(z - a)
            let amp = sqrtf(meanPower) * 2 / Float(fftSize)
            let tilt = Float(b) * 1.7
            let db = 20 * log10f(amp + 1e-7) + tilt
            let norm = max(0, min(1, (db + 58) / 46))
            out[b] = norm
        }

        let level = min(1, rms * 6)
        return (bands: out, level: level)
    }

    func makeBufferSize() -> AVAudioFrameCount {
        AVAudioFrameCount(fftSize)
    }
}
