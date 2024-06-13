# FastViT Sample 

This sample demonstrates the use of [FastViT](https://github.com/apple/ml-fastvit) converted to Core ML using [coremltools](https://github.com/apple/coremltools). FastViT is a small and very fast model for image classification.

## Instructions

1. [Download FastViTT8F16.mlpackage](#download) from the Hugging Face Hub and place it inside the `models` folder of the project.
2. Open `FastViTSample.xcodeproj` in XCode.
3. Build & run the project!

The FastViT model was introduced in the paper [FastViT: A Fast Hybrid Vision Transformer using Structural Reparameterization](https://arxiv.org/abs/2303.14189) by Pavan Kumar Anasosalu Vasu et al. and first released in [this repository](https://github.com/apple/ml-fastvit).

## Download

Core ML packages are available in:
- [apple/coreml-FastViT-T8](https://huggingface.co/apple/coreml-FastViT-T8). Small version (4M parameters).
- [apple/coreml-FastViT-MA36](https://huggingface.co/apple/coreml-FastViT-MA36). Larger version (44M parameters) with better accuracy.

Install `huggingface-cli`

```bash
brew install huggingface-cli
```

Download `FastViTT8F16.mlpackage` to the `models` directory:

```bash
huggingface-cli download \
  --local-dir models --local-dir-use-symlinks False \
  apple/coreml-FastViT-T8 \
  --include "FastViTT8F16.mlpackage/*"
```

FastViT-T8 is the smallest version of the model, with 4M parameters. You can also try the larger and more accurate FastViT-MA36 (44M parameters), downloading it from [apple/coreml-FastViT-MA36](https://huggingface.co/apple/coreml-FastViT-MA36).
