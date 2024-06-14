# CoreML Examples

This repository contains a collection of CoreML demo apps, with optimized models for the Apple Neural Engine™️.

||||
| ------------- | ------------- |  ------------- |
| <video src="https://github.com/huggingface/coreml-examples/assets/1177582/b1e8ee23-90a0-403a-ab15-a57d55959ce7">  | <video src="https://github.com/FL33TW00D/coreml-examples/assets/45471420/a457c007-2d27-4bf0-9cb0-e1e0c298732a">|<video src="https://github.com/huggingface/coreml-examples/assets/1177582/6cc4c180-c345-45b3-9a6b-a18f078df251">|

The models showcased include:

| Sample Code                                                | Task                       | Core ML packages                                                                                                                                                |
|------------------------------------------------------------|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [FastViT](FastViTSample/README.md)                         | Image Classification       | [ apple/coreml-FastViT-T8 ]( https://huggingface.co/apple/coreml-FastViT-T8 ) [ apple/coreml-FastViT-MA36 ]( https://huggingface.co/apple/coreml-FastViT-MA36 ) |
| [Depth Anything (small)](depth-anything-example/README.md) | Monocular Depth Estimation | [apple/coreml-depth-anything-small](https://huggingface.co/apple/coreml-depth-anything-small)                                                                   |
| [DETR (ResNet 50)](SemanticSegmentationSample/README.md)   | Semantic Segmentation      | [ apple/coreml-detr-semantic-segmentation ]( https://huggingface.co/apple/coreml-detr-semantic-segmentation )                                                   |


We leverage [coremltools](https://github.com/apple/coremltools) for testing and implementing these optimisations. You can read more about it [here](https://apple.github.io/coremltools/docs-guides/source/opt-palettization-api.html).
