#include "CRevModel.h"

CRevModel::CRevModel() {
    buffers[0] = new float[1116];
    buffers[1] = new float[1139];
    buffers[2] = new float[1188];
    buffers[3] = new float[1211];
    buffers[4] = new float[1277];
    buffers[5] = new float[1300];
    buffers[6] = new float[1356];
    buffers[7] = new float[1379];
    buffers[8] = new float[1422];
    buffers[9] = new float[1445];
    buffers[10] = new float[1491];
    buffers[11] = new float[1514];
    buffers[12] = new float[1557];
    buffers[13] = new float[1580];
    buffers[14] = new float[1617];
    buffers[15] = new float[1640];

    buffers[16] = new float[556];
    buffers[17] = new float[579];
    buffers[18] = new float[441];
    buffers[19] = new float[464];
    buffers[20] = new float[341];
    buffers[21] = new float[364];
    buffers[22] = new float[225];
    buffers[23] = new float[248];

    combL[0].SetBuffer(buffers[0], 1116);
    combR[0].SetBuffer(buffers[1], 1139);
    combL[1].SetBuffer(buffers[2], 1188);
    combR[1].SetBuffer(buffers[3], 1211);
    combL[2].SetBuffer(buffers[4], 1277);
    combR[2].SetBuffer(buffers[5], 1300);
    combL[3].SetBuffer(buffers[6], 1356);
    combR[3].SetBuffer(buffers[7], 1379);
    combL[4].SetBuffer(buffers[8], 1422);
    combR[4].SetBuffer(buffers[9], 1445);
    combL[5].SetBuffer(buffers[10], 1491);
    combR[5].SetBuffer(buffers[11], 1514);
    combL[6].SetBuffer(buffers[12], 1557);
    combR[6].SetBuffer(buffers[13], 1580);
    combL[7].SetBuffer(buffers[14], 1617);
    combR[7].SetBuffer(buffers[15], 1640);

    allpassL[0].SetBuffer(buffers[16], 556);
    allpassR[0].SetBuffer(buffers[17], 579);
    allpassL[1].SetBuffer(buffers[18], 441);
    allpassR[1].SetBuffer(buffers[19], 464);
    allpassL[2].SetBuffer(buffers[20], 341);
    allpassR[2].SetBuffer(buffers[21], 364);
    allpassL[3].SetBuffer(buffers[22], 225);
    allpassR[3].SetBuffer(buffers[23], 248);

    allpassL[0].SetFeedback(0.5);
    allpassR[0].SetFeedback(0.5);
    allpassL[1].SetFeedback(0.5);
    allpassR[1].SetFeedback(0.5);
    allpassL[2].SetFeedback(0.5);
    allpassR[2].SetFeedback(0.5);
    allpassL[3].SetFeedback(0.5);
    allpassR[3].SetFeedback(0.5);

    SetWet(0.167);
    SetRoomSize(0.5);
    SetDry(0.25);
    SetDamp(0.5);
    SetWidth(1.0);
    SetMode(0.0);

    Reset();
}

CRevModel::~CRevModel() {
    for (auto &buffer : buffers) {
        delete[] buffer;
    }
}

float CRevModel::GetDamp() {
    return damp / 0.4f;
}

float CRevModel::GetDry() {
    return dry / 2.0f;
}

float CRevModel::GetMode() {
    if (this->mode >= 0.5) {
        return 1.0;
    }
    return this->mode;
}

float CRevModel::GetRoomSize() {
    return (this->roomSize - 0.7f) / 0.28f;
}

float CRevModel::GetWet() {
    return wet / 3.0f;
}

float CRevModel::GetWidth() {
    return width;
}

void CRevModel::Mute() {
    if (GetMode() >= 0.5) return;

    for (int i = 0; i < 8; i++) {
        combL[i].Mute();
        combR[i].Mute();
    }

    for (int i = 0; i < 4; i++) {
        allpassL[i].Mute();
        allpassR[i].Mute();
    }
}

void CRevModel::ProcessReplace(float *bufL, float *bufR, uint32_t size) {
    for (uint32_t idx = 0; idx < size * 2; idx += 2) {
        float outL = 0.0;
        float outR = 0.0;
        float input = (bufL[idx] + bufR[idx]) * this->gain;

        for (uint32_t i = 0; i < 8; i++) {
            outL += this->combL[i].Process(input);
            outR += this->combR[i].Process(input);
        }

        for (uint32_t i = 0; i < 4; i++) {
            outL = this->allpassL[i].Process(outL);
            outR = this->allpassR[i].Process(outR);
        }

        bufL[idx] = outL * this->unknown1 + outR * this->unknown2 + bufL[idx] * this->dry;
        bufR[idx] = outR * this->unknown1 + outL * this->unknown2 + bufR[idx] * this->dry;
    }
}

void CRevModel::Reset() {
    if (GetMode() >= 0.5) return;

    for (int i = 0; i < 8; i++) {
        combL[i].Mute();
        combR[i].Mute();
    }

    for (int i = 0; i < 4; i++) {
        allpassL[i].Mute();
        allpassR[i].Mute();
    }
}

void CRevModel::SetDamp(float damp) {
    this->damp = damp * 0.4f;
    UpdateCoeffs();
}

void CRevModel::SetDry(float dry) {
    this->dry = dry * 2.0f;
}

void CRevModel::SetMode(float mode) {
    this->mode = mode;
    UpdateCoeffs();
}

void CRevModel::SetRoomSize(float roomSize) {
    this->roomSize = (roomSize * 0.28f) + 0.7f;
    UpdateCoeffs();
}

void CRevModel::SetWet(float wet) {
    this->wet = wet * 3.0f;
    UpdateCoeffs();
}

void CRevModel::SetWidth(float width) {
    this->width = width;
    UpdateCoeffs();
}

void CRevModel::UpdateCoeffs() {
    this->unknown1 = this->wet * (this->width / 2.0f + 0.5f);
    this->unknown2 = this->wet * (1.0f - this->width) / 2.0f;

    if (this->mode >= 0.5) {
        this->internalRoomSize = 1.0;
        this->internalDamp = 0.0;
        this->gain = 0.0;
    } else {
        this->internalRoomSize = this->roomSize;
        this->internalDamp = this->damp;
        this->gain = 0.015;
    }

    for (int i = 0; i < 8; i++) {
        this->combL[i].SetFeedback(this->internalRoomSize);
        this->combL[i].SetDamp(this->internalDamp);
        this->combR[i].SetFeedback(this->internalRoomSize);
        this->combR[i].SetDamp(this->internalDamp);
    }
}
