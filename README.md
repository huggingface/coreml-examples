# CoreML Examples

This repository contains a collection of CoreML demo apps, with optimized models for the Apple Neural Engine™️.

||||
| ------------- | ------------- |  ------------- |
| <video src="https://github.com/huggingface/coreml-examples/assets/45471420/547eeb0a-ca60-4978-bf12-07da8e0b9330">  | <video src="https://github.com/huggingface/coreml-examples/assets/45471420/13c53f2f-0fae-4ee7-83fe-95315a072b8b">|<video src="https://github.com/huggingface/coreml-examples/assets/45471420/6afecb82-e1e6-45fd-b060-953f94d46deb">|

The models showcased include:

| Sample Code                                                | Task                       | Core ML packages                                                                                                                                                |
|------------------------------------------------------------|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [FastViT](FastViTSample/README.md)                         | Image Classification       | [ apple/coreml-FastViT-T8 ]( https://huggingface.co/apple/coreml-FastViT-T8 ) [ apple/coreml-FastViT-MA36 ]( https://huggingface.co/apple/coreml-FastViT-MA36 ) |
| [Depth Anything (small)](depth-anything-example/README.md) | Monocular Depth Estimation | [apple/coreml-depth-anything-small](https://huggingface.co/apple/coreml-depth-anything-small)                                                                   |
| [DETR (ResNet 50)](SemanticSegmentationSample/README.md)   | Semantic Segmentation      | [ apple/coreml-detr-semantic-segmentation ]( https://huggingface.co/apple/coreml-detr-semantic-segmentation )                                                   |


We leverage [coremltools](https://github.com/apple/coremltools) for testing and implementing these optimisations. You can read more about it [here](https://apple.github.io/coremltools/docs-guides/source/opt-palettization-api.html).