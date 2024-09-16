# CoreML Examples

This repository contains a collection of CoreML demo apps, with optimized models for the Apple Neural Engine™️. It also hosts tutorials and other resources you can use in your own projects.

## Demo Apps

||||
| ------------- | ------------- |  ------------- |
| <video src="https://github.com/huggingface/coreml-examples/assets/45471420/04f13819-bdae-4843-9631-940bd9b21b4e">  | <video src="https://github.com/huggingface/coreml-examples/assets/45471420/e760cf8b-0f11-4b95-9db6-db4c46d954d6">|<video src="https://github.com/huggingface/coreml-examples/assets/45471420/4b71b9e9-3d63-400c-868e-f0734aba0a6f">|

The models showcased include:

| Sample Code                                                | Task                       | Core ML packages                                                                                                                                                |
|------------------------------------------------------------|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [FastViT](FastViTSample/README.md)                         | Image Classification       | [ apple/coreml-FastViT-T8 ]( https://huggingface.co/apple/coreml-FastViT-T8 ) [ apple/coreml-FastViT-MA36 ]( https://huggingface.co/apple/coreml-FastViT-MA36 ) |
| [Depth Anything V2 (small)](depth-anything-example/README.md) | Monocular Depth Estimation | [apple/coreml-depth-anything-v2-small](https://huggingface.co/apple/coreml-depth-anything-small)                                                                   |
| [DETR (ResNet 50)](SemanticSegmentationSample/README.md)   | Semantic Segmentation      | [ apple/coreml-detr-semantic-segmentation ]( https://huggingface.co/apple/coreml-detr-semantic-segmentation )                                                   |


We leverage [coremltools](https://github.com/apple/coremltools) for testing and implementing these optimisations. You can read more about it [here](https://apple.github.io/coremltools/docs-guides/source/opt-palettization-api.html).

## Tutorials

- How to convert Depth Anything v2 for GPU and Neural Engine. [Source code notebook](https://github.com/huggingface/coreml-examples/tutorials/depth-anything-coreml-guide.ipynb) <a target="_blank" href="https://colab.research.google.com/github/huggingface/coreml-examples/tutorials/depth-anything-coreml-guide.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"/>
</a>




