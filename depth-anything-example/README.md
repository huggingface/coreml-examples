# Depth Anything Sample 

This sample demonstrates the usage of [Depth Anything (small)](https://huggingface.co/LiheYoung/depth-anything-small-hf) converted to Core ML. It allows for real-time depth estimation on iOS devices.

We leverage [coremltools](https://github.com/apple/coremltools) for model conversion and compression. You can read more about it [here](https://apple.github.io/coremltools/docs-guides/source/opt-palettization-api.html).

## Instructions

1. [Download DepthAnythingSmallF16.mlpackage](#download) from the Hugging Face Hub and place it inside the `DepthApp/models` folder.
2. Open `DepthSample.xcodeproj` in XCode.
3. Build & run the project!

Depth Anything model was introduced in the paper [Depth Anything: Unleashing the Power of Large-Scale Unlabeled Data](https://arxiv.org/abs/2401.10891) by Lihe Yang et al. and first released in [this repository](https://github.com/LiheYoung/Depth-Anything).

## Model description

Depth Anything leverages the [DPT](https://huggingface.co/docs/transformers/model_doc/dpt) architecture with a [DINOv2](https://huggingface.co/docs/transformers/model_doc/dinov2) backbone.

The model is trained on ~62 million images, obtaining state-of-the-art results for both relative and absolute depth estimation.

<img src="https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/transformers/model_doc/depth_anything_overview.jpg"
alt="drawing" width="600"/>

<small> Depth Anything overview. Taken from the <a href="https://arxiv.org/abs/2401.10891">original paper</a>.</small>

## Download

Core ML packages are available in [apple/coreml-depth-anything-small](https://huggingface.co/apple/coreml-depth-anything-small).

Install `huggingface-cli`

```bash
brew install huggingface-cli
```

Download `DepthAnythingSmallF16.mlpackage` to the `models` directory:

```bash
huggingface-cli download \
  --local-dir models --local-dir-use-symlinks False \
  apple/coreml-depth-anything-small \
  --include "DepthAnythingSmallF16.mlpackage/*"
```

To download all the model versions, including quantized ones, skip the `--include` argument.
