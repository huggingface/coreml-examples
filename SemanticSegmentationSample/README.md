# Semantic Segmentation Sample with DETR

This sample demonstrates the use of [DETR](https://huggingface.co/facebook/detr-resnet-50) converted to Core ML. It allows semantic segmentation on iOS devices, where each pixel in an image is classified according to the most probable category it belongs to.

We leverage [coremltools](https://github.com/apple/coremltools) for model conversion and compression. You can read more about it [here](https://apple.github.io/coremltools/docs-guides/source/opt-palettization-api.html).

## Instructions

1. [Download DETRResnet50SemanticSegmentationF16.mlpackage](#download) from the Hugging Face Hub and place it inside the `models` folder of the project.
2. Open `SemanticSegmentationSample.xcodeproj` in Xcode.
3. Build & run the project!

DEtection TRansformer (DETR) was introduced in the paper [End-to-End Object Detection with Transformers](https://arxiv.org/abs/2005.12872) by Carion et al. and first released in [this repository](https://github.com/facebookresearch/detr).

## Download

Core ML packages are available in [apple/coreml-detr-semantic-segmentation](https://huggingface.co/apple/coreml-detr-semantic-segmentation).
Install `huggingface-cli`

```bash
brew install huggingface-cli
```

Download `DETRResnet50SemanticSegmentationF16.mlpackage` to the `models` directory:

```bash
huggingface-cli download \
  --local-dir models --local-dir-use-symlinks False \
  apple/coreml-detr-semantic-segmentation \
  --include "DETRResnet50SemanticSegmentationF16.mlpackage/*"
```

To download all the model versions, including quantized ones, skip the `--include` argument.
