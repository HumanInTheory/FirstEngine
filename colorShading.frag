#version 330

uniform sampler2D ourTexture;

in vec2 fragmentPosition;
in vec2 fragmentTexturePosition;
in vec3 fragmentColor;

out vec4 color;

void main() {
    color = texture(ourTexture, fragmentTexturePosition);
}