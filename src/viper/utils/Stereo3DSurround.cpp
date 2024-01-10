#include "Stereo3DSurround.h"

Stereo3DSurround::Stereo3DSurround() {
    this->middleImage = 1.0;
    this->stereoWiden = 0.0;
    this->coeffLeft = 0.5;
    this->coeffRight = 0.5;
}

void Stereo3DSurround::Process(float *samples, uint32_t size) {
    if (size == 0) return;

    uint32_t pairs = size / 2;
    uint32_t remainder = size % 2;

    if (pairs > 0) {
        for (uint32_t i = 0; i < pairs; i++) {
            float a = this->coeffLeft * (samples[4 * i] + samples[4 * i + 1]);
            float b = this->coeffRight * (samples[4 * i + 1] - samples[4 * i]);
            float c = this->coeffLeft * (samples[4 * i + 2] + samples[4 * i + 3]);
            float d = this->coeffRight * (samples[4 * i + 3] - samples[4 * i + 2]);

            samples[4 * i] = a - b;
            samples[4 * i + 1] = a + b;
            samples[4 * i + 2] = c - d;
            samples[4 * i + 3] = c + d;
        }
    }

    if (remainder > 0) {
        for (uint32_t i = 4 * pairs; i < 2 * size; i += 2) {
            float a = samples[i];
            float b = samples[i + 1];
            float c = this->coeffLeft * (a + b);
            float d = this->coeffRight * (b - a);

            samples[i] = c - d;
            samples[i + 1] = c + d;
        }
    }
}

inline void Stereo3DSurround::ConfigureVariables() {
    float tmp = this->stereoWiden + 1.0f;

    float x = tmp + 1.0f;
    float y;
    if (x < 2.0) {
        y = 0.5;
    } else {
        y = 1.0f / x;
    }

    this->coeffLeft = this->middleImage * y;
    this->coeffRight = tmp * y;
}

void Stereo3DSurround::SetMiddleImage(float middleImage) {
    this->middleImage = middleImage;
    this->ConfigureVariables();
}

void Stereo3DSurround::SetStereoWiden(float stereoWiden) {
    this->stereoWiden = stereoWiden;
    this->ConfigureVariables();
}
