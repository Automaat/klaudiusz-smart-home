# Custom Wake Word Models

## pl_klaudiusz.onnx

- **Wake word:** Klaudiusz (Polish)
- **Format:** ONNX (201KB)
- **Training date:** 2026-02-08
- **Training samples:** 1200 synthetic (Piper TTS: pl_PL-gosia-medium + pl_PL-darkman-medium)
- **Training steps:** 10,000
- **Dataset:** 17GB ACAV100M pre-computed features for negative samples
- **Expected accuracy:** 60%+ (experimental Polish support)

### Training Details

- **Generated with:** piper-sample-generator
- **Trained with:** openWakeWord v0.5.1
- **Voices:** 
  - pl_PL-gosia-medium (600 samples, resampled to 16kHz)
  - pl_PL-darkman-medium (600 samples, resampled to 16kHz)
- **Split:** 90% train (1080 samples) / 10% test (120 samples)
- **Target metrics:**
  - Accuracy: 60%
  - Recall: 40%
  - False positives: 0.2 per hour

### Known Limitations

- **Experimental:** openWakeWord embedding model trained on English data
- **Lower accuracy:** 60-90% expected (vs 95%+ for English wake words)
- **Accent sensitivity:** Polish regional accents may affect detection
- **May require tuning:** Detection threshold might need adjustment based on real-world testing

### Deployment

Place in `customModelsDirectories` for wyoming-openwakeword service:

```nix
services.wyoming.openwakeword.servers.default = {
  enable = true;
  uri = "tcp://127.0.0.1:10400";
  customModelsDirectories = [ ./wake-words ];
  preloadModels = [ "pl_klaudiusz" ];
};
```

### Future Improvements

- Collect real voice recordings for retraining
- Add more Polish voice models for diversity
- Train on variations: "hej Klaudiusz", "Klaudiuszu" (vocative case)
- Monitor false positive rate over time
- Consider Raven (template-based) if accuracy insufficient

### References

- Training guide: `docs/wake-word-training.md`
- openWakeWord: https://github.com/dscripka/openWakeWord
- Piper TTS: https://github.com/rhasspy/piper
- Wyoming protocol: https://github.com/rhasspy/wyoming-openwakeword
