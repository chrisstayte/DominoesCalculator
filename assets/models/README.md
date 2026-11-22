# Domino models

The app uses `domino-v2-01` to locate rotated tiles and
`pips-v3-mnv2-mixed-01` to classify each half as 0 through 15.
The detector checkpoint is unchanged. Model hashes, tensor shapes and input
ranges are recorded in `domino_models.json` and checked at initialization.

- Detector: YOLO26n-OBB, FP32 LiteRT, RGB float32 **NCHW** `[1,3,640,640]`,
  normalized 0–1 with square letterbox padding 114. Output `[1,6,8400]` is
  normalized cx/cy/w/h, confidence, angle in radians. Rotated Fast-NMS uses
  confidence >0.25 and probabilistic IoU 0.7, maximum 300 tiles.
- Classifier: MobileNetV2 alpha 0.5 with ImageNet initialization, FP16 weights,
  RGB float32 **NHWC** `[1,128,128,3]`, **0–255**, output probabilities `[1,16]`.
  Scaling is embedded in the classifier; dividing by 255 again breaks inference.
- Each quadrilateral is rectified to 256×128 with OpenCV-compatible perspective
  sampling and border value 127, then split into two 128×128 halves.

Ultralytics supplies its detector code and models under AGPL-3.0 or an Enterprise
license: <https://www.ultralytics.com/license>. The upstream license is included
in `licenses/Ultralytics-AGPL-3.0.txt`. The detector was fine-tuned from
`yolo26n-obb.pt` with `ultralytics==8.4.144`, and its weights are credited as
AGPL-3.0. The app's own code is MIT (see the repository `LICENSE`); how the
bundled AGPL weights fit with that is still an open compliance question. The classifier uses Keras MobileNetV2; Keras source is Apache-2.0:
<https://github.com/keras-team/keras/blob/master/LICENSE>.

Private photos, annotations, Drive identifiers, credentials and raw training
outputs are excluded. See the mobile integration notes for verification and
local build instructions.
